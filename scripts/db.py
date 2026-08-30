#!/usr/bin/env python3
"""
Executa SQL no Autonomous Database via wallet.

  .venv/bin/python scripts/db.py sql/setup/00_usuarios.sql
  .venv/bin/python scripts/db.py -u silver sql/silver/01_slv_internacao.sql
  .venv/bin/python scripts/db.py -q "SELECT COUNT(*) FROM brz_sih_rd" -u bronze

Senhas vem de .claude/oci.secrets — nunca sao impressas.
"""
from __future__ import annotations
import argparse, os, re, sys, time
from pathlib import Path
import oracledb

ROOT = Path(__file__).resolve().parent.parent


def carregar_env(arquivo: Path) -> dict:
    d = {}
    if arquivo.exists():
        for l in arquivo.read_text().splitlines():
            l = l.strip()
            if l and not l.startswith("#") and "=" in l:
                k, v = l.split("=", 1)
                d[k.strip()] = v.strip()
    return d


CFG = {**carregar_env(ROOT / ".claude" / "oci.env"),
       **carregar_env(ROOT / ".claude" / "oci.secrets")}
WALLET = os.path.expanduser(CFG.get("ADB_WALLET_DIR", "~/.oci/wallets/susradar"))
SENHAS = {"admin": "ADB_ADMIN_PASSWORD", "bronze": "BRONZE_PASSWORD", "silver": "SILVER_PASSWORD", "gold": "GOLD_PASSWORD"}


def conectar(usuario: str, servico: str = "medium"):
    chave = SENHAS.get(usuario.lower())
    if not chave or chave not in CFG:
        sys.exit(f"[ERRO] senha de '{usuario}' ausente em .claude/oci.secrets")
    dsn = f"{CFG.get('ADB_NAME','SUSRADAR').lower()}_{servico}"
    return oracledb.connect(user=usuario, password=CFG[chave], dsn=dsn,
                            config_dir=WALLET, wallet_location=WALLET,
                            wallet_password=CFG["WALLET_PASSWORD"])


def sem_comentario(linha: str) -> str:
    """Remove comentario '--' respeitando aspas. Comentario inline depois de ';'
    fazia o ';' deixar de ser o fim da linha e dois comandos se fundirem."""
    fora, aspa = [], None
    i = 0
    while i < len(linha):
        c = linha[i]
        if aspa:
            fora.append(c)
            if c == aspa:
                aspa = None
        elif c in "'\"":
            aspa = c; fora.append(c)
        elif c == "-" and i + 1 < len(linha) and linha[i+1] == "-":
            break
        else:
            fora.append(c)
        i += 1
    return "".join(fora).rstrip()


def redigir(texto: str) -> str:
    """Mascara segredo antes de imprimir. IDENTIFIED BY nunca vai pro terminal."""
    texto = re.sub(r"(IDENTIFIED\s+BY\s+)(\"[^\"]*\"|'[^']*'|\S+)", r"\1***", texto, flags=re.I)
    texto = re.sub(r"((?:password|private_key|secret)\s*=>\s*)('[^']*')", r"\1'***'", texto, flags=re.I)
    return texto


def dividir(sql: str) -> list[str]:
    """Separa em comandos. Blocos PL/SQL terminam em '/' na propria linha."""
    sql = "\n".join(sem_comentario(l) for l in sql.splitlines())
    cmds, buf, em_bloco = [], [], False
    for linha in sql.splitlines():
        s = linha.strip()
        if re.match(r"^(BEGIN|DECLARE|CREATE\s+(OR\s+REPLACE\s+)?(PROCEDURE|FUNCTION|TRIGGER|PACKAGE))",
                    s, re.I):
            em_bloco = True
        if em_bloco:
            if s == "/":
                cmds.append("\n".join(buf)); buf, em_bloco = [], False
            else:
                buf.append(linha)
            continue
        buf.append(linha)
        if s.endswith(";"):
            c = "\n".join(buf).strip().rstrip(";").strip()
            if c:
                cmds.append(c)
            buf = []
    resto = "\n".join(buf).strip().rstrip(";").strip()
    if resto:
        cmds.append(resto)
    return cmds


def rodar(con, cmds: list[str], parar_no_erro: bool) -> int:
    erros = 0
    for i, c in enumerate(cmds, 1):
        rotulo = redigir(" ".join(c.split()))[:78]
        t0 = time.time()
        try:
            with con.cursor() as cur:
                cur.execute(c)
                if cur.description:
                    cols = [d[0] for d in cur.description]
                    linhas = cur.fetchall()
                    print(f"[{i}/{len(cmds)}] {rotulo}")
                    print("    " + " | ".join(cols))
                    for r in linhas[:50]:
                        print("    " + " | ".join("" if v is None else str(v) for v in r))
                    if len(linhas) > 50:
                        print(f"    ... +{len(linhas)-50} linhas")
                else:
                    print(f"[{i}/{len(cmds)}] ok ({time.time()-t0:.1f}s)  {rotulo}")
            con.commit()
        except Exception as e:
            erros += 1
            print(f"[{i}/{len(cmds)}] ERRO  {rotulo}")
            print(f"    {str(e).splitlines()[0]}")
            if parar_no_erro:
                return erros
    return erros


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("arquivos", nargs="*")
    ap.add_argument("-u", "--usuario", default="ADMIN")
    ap.add_argument("-s", "--servico", default="medium")
    ap.add_argument("-q", "--query")
    ap.add_argument("--continuar", action="store_true", help="nao para no primeiro erro")
    a = ap.parse_args()

    con = conectar(a.usuario, a.servico)
    print(f"conectado: {a.usuario}@{CFG.get('ADB_NAME','SUSRADAR').lower()}_{a.servico}")
    total = 0
    try:
        if a.query:
            total += rodar(con, [a.query], not a.continuar)
        for f in a.arquivos:
            p = Path(f)
            print(f"\n--- {p} ---")
            total += rodar(con, dividir(p.read_text(encoding="utf-8")), not a.continuar)
    finally:
        con.close()
    if total:
        sys.exit(f"\n{total} erro(s)")
    print("\nsem erros")


if __name__ == "__main__":
    main()
