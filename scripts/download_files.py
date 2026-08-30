#!/usr/bin/env python3
"""
SUS Radar 360 — Download + conversão de microdados DATASUS (SP).
Carga MANUAL e ÚNICA. Baixa DBC via FTP oficial e converte para Parquet.

Uso:
    pip install datasus-dbc dbfread pandas pyarrow
    python baixa_datasus.py                # baixa o conjunto padrão (SP)
    python baixa_datasus.py --uf SP --sih-meses 202501 202502 202503

Saída:
    data/raw/<sistema>/*.dbc         (bruto, como veio do DATASUS)
    data/processed/<sistema>/*.parquet
    data/manifesto.csv               (arquivo, linhas, colunas, status)

Não depende de pysus (evita quebras de API). Só FTP + datasus-dbc + dbfread.
"""
from __future__ import annotations
import argparse, ftplib, socket, sys, csv, struct, datetime as dt
from pathlib import Path

# ---- dependências de leitura (instale com o pip acima) ----
try:
    import datasus_dbc            # decompress .dbc -> .dbf
    from dbfread import DBF       # ler .dbf
    import pandas as pd
except ImportError as e:
    sys.exit(f"[ERRO] Instale as libs: pip install datasus-dbc dbfread pandas pyarrow\n{e}")

FTP_HOST = "ftp.datasus.gov.br"
BASE = "/dissemin/publicos"
# Caminhos ancorados na raiz do repo, nao no diretorio de trabalho — o script
# vive em scripts/ e precisa funcionar chamado de qualquer lugar.
ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw"
PROC = ROOT / "data" / "processed"
MANIFESTO = ROOT / "data" / "manifesto.csv"


def ftp_connect() -> ftplib.FTP:
    socket.setdefaulttimeout(60)
    ftp = ftplib.FTP(FTP_HOST)
    ftp.login()                 # anônimo
    ftp.set_pasv(True)
    return ftp


def baixar(ftp: ftplib.FTP, remoto: str, destino: Path) -> bool:
    """Baixa um arquivo do FTP. Retorna True se ok."""
    destino.parent.mkdir(parents=True, exist_ok=True)
    try:
        with open(destino, "wb") as f:
            ftp.retrbinary(f"RETR {remoto}", f.write)
        print(f"  ✓ {remoto}  ({destino.stat().st_size/1e6:.1f} MB)")
        return True
    except ftplib.error_perm as e:
        print(f"  ✗ {remoto}  -> {e} (arquivo pode não existir p/ o período)")
        if destino.exists():
            destino.unlink()
        return False


def reparar_dbf(dbf: Path) -> bool:
    """Corrige o terminador do cabecalho. Alguns DBF do DATASUS (visto no CNES ST)
    gravam 0x00 no lugar do 0x0D que fecha a lista de campos. O dbfread le
    descritores de 32 bytes ate achar o 0x0D; sem ele, varre o arquivo inteiro e
    estoura com "unpack requires a buffer of 32 bytes". Retorna True se corrigiu."""
    with open(dbf, "r+b") as f:
        f.seek(8)
        header_len = struct.unpack("<H", f.read(2))[0]
        fim = header_len - 1
        f.seek(fim)
        if f.read(1) == b"\x0d":
            return False
        f.seek(fim)
        f.write(b"\x0d")
    return True


def dbc_para_parquet(dbc: Path, sistema: str) -> dict:
    """Converte .dbc -> .dbf -> parquet. Retorna linha do manifesto."""
    dbf = dbc.with_suffix(".dbf")
    out = PROC / sistema / (dbc.stem + ".parquet")
    out.parent.mkdir(parents=True, exist_ok=True)
    try:
        datasus_dbc.decompress(str(dbc), str(dbf))
        if reparar_dbf(dbf):
            print("    · cabecalho do DBF sem terminador 0x0D — corrigido")
        df = pd.DataFrame(iter(DBF(str(dbf), encoding="latin-1", raw=False)))
        df.to_parquet(out, index=False)
        dbf.unlink(missing_ok=True)
        print(f"    → {out.name}: {df.shape[0]:,} linhas × {df.shape[1]} colunas")
        print(f"      colunas: {', '.join(list(df.columns)[:25])}"
              + (" ..." if df.shape[1] > 25 else ""))
        return {"arquivo": dbc.name, "sistema": sistema, "linhas": df.shape[0],
                "colunas": df.shape[1], "parquet": str(out), "status": "ok"}
    except Exception as e:
        print(f"    ✗ falha ao converter {dbc.name}: {e}")
        return {"arquivo": dbc.name, "sistema": sistema, "linhas": "", "colunas": "",
                "parquet": "", "status": f"erro: {e}"}


def ultimos_meses(n: int) -> list[str]:
    """Últimos n meses no formato AAAAMM, começando 3 meses atrás (defasagem SIH)."""
    hoje = dt.date.today().replace(day=1)
    ref = hoje - dt.timedelta(days=90)          # ~3 meses de defasagem de consolidação
    out = []
    y, m = ref.year, ref.month
    for _ in range(n):
        out.append(f"{y}{m:02d}")
        m -= 1
        if m == 0:
            m, y = 12, y - 1
    return sorted(out)


def alvos(uf: str, sih_meses: list[str], cnes_mes: str,
          sim_anos: list[str], sinasc_anos: list[str]) -> list[tuple[str, str]]:
    """Lista (caminho_remoto, sistema) do conjunto SP recomendado."""
    L: list[tuple[str, str]] = []
    for ym in sih_meses:                        # SIHSUS RD (AIH reduzida), mensal
        yy = ym[2:6]
        L.append((f"{BASE}/SIHSUS/200801_/Dados/RD{uf}{yy}.dbc", "SIHSUS"))
    yy = cnes_mes[2:6]
    L.append((f"{BASE}/CNES/200508_/Dados/LT/LT{uf}{yy}.dbc", "CNES"))   # Leitos
    L.append((f"{BASE}/CNES/200508_/Dados/ST/ST{uf}{yy}.dbc", "CNES"))   # Estabelecimentos
    for ano in sim_anos:                        # SIM (óbitos), anual
        L.append((f"{BASE}/SIM/CID10/DORES/DO{uf}{ano}.dbc", "SIM"))
    for ano in sinasc_anos:                     # SINASC (nascidos), anual
        L.append((f"{BASE}/SINASC/NOV/DNRES/DN{uf}{ano}.dbc", "SINASC"))
    return L


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--uf", default="SP")
    ap.add_argument("--sih-meses", nargs="*", default=ultimos_meses(24),
                    help="meses AAAAMM do SIH RD (padrão: últimos 24)")
    ap.add_argument("--cnes-mes", default=ultimos_meses(1)[-1],
                    help="competência AAAAMM do CNES (padrão: mais recente)")
    ap.add_argument("--sim-anos", nargs="*", default=["2021", "2022", "2023"])
    ap.add_argument("--sinasc-anos", nargs="*", default=["2021", "2022", "2023"])
    args = ap.parse_args()

    print(f"UF={args.uf} | SIH meses={args.sih_meses[0]}..{args.sih_meses[-1]} "
          f"({len(args.sih_meses)}) | CNES={args.cnes_mes} | "
          f"SIM={args.sim_anos} | SINASC={args.sinasc_anos}\n")

    lista = alvos(args.uf, args.sih_meses, args.cnes_mes, args.sim_anos, args.sinasc_anos)
    ftp = ftp_connect()
    manifesto = []
    try:
        for remoto, sistema in lista:
            nome = remoto.rsplit("/", 1)[-1]
            destino = RAW / sistema / nome
            print(f"[{sistema}] {nome}")
            if destino.exists():
                print("  (já baixado, pulando download)")
            elif not baixar(ftp, remoto, destino):
                manifesto.append({"arquivo": nome, "sistema": sistema, "linhas": "",
                                  "colunas": "", "parquet": "", "status": "nao encontrado"})
                continue
            manifesto.append(dbc_para_parquet(destino, sistema))
    finally:
        ftp.quit()

    MANIFESTO.parent.mkdir(parents=True, exist_ok=True)
    with open(MANIFESTO, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["arquivo", "sistema", "linhas", "colunas",
                                          "parquet", "status"])
        w.writeheader(); w.writerows(manifesto)

    ok = sum(1 for m in manifesto if m["status"] == "ok")
    print(f"\nConcluído: {ok}/{len(manifesto)} arquivos convertidos. "
          f"Manifesto em {MANIFESTO}")


if __name__ == "__main__":
    main()