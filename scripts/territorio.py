#!/usr/bin/env python3
"""
SUS Radar 360 — carga da Base Territorial: nomes de municipio, coordenadas e o
de/para municipio -> regiao de saude.

Todo o painel agrega por regiao de saude e NENHUMA base de microdado do DATASUS
traz esse agrupamento de forma usavel: o SIH so tem codigo IBGE de municipio e o
REGSAUDE do CNES e texto livre (56% em branco, 291 valores distintos). O de/para
oficial mora em outra arvore do FTP — /territorio/tabelas/, a Base Territorial do
Ministerio da Saude, publicada a cada dois meses.

    ftp.datasus.gov.br/territorio/tabelas/<AAAA>/<MM>-base_territorial_<mesAA>.zip
        rl_municip_regsaud.csv   CO_MUNICIP;CO_REGSAUD          (5.572 municipios)
        tb_regsaud.csv           CO_REGSAUD,CO_STATUS,DS_NOME    (466 regioes)
        tb_municip.csv           CO_MUNICIP;...;DS_NOME;...;NU_LATITUD;NU_LONGIT

Uso:
    .venv/bin/python scripts/territorio.py              # baixa a mais recente e carrega
    .venv/bin/python scripts/territorio.py --so-baixar  # nao toca no banco
    .venv/bin/python scripts/territorio.py --zip data/raw/TERRITORIO/x.zip

Saida:
    data/raw/TERRITORIO/base_territorial_<mesAA>.zip
    data/processed/TERRITORIO/territorio.parquet
    SILVER.SLV_REGIAO_SAUDE
    SILVER.SLV_MUNICIPIO.{nome_municipio,regiao_saude,cod_regiao_saude,latitude,longitude}
"""
from __future__ import annotations
import argparse, ftplib, io, re, socket, sys, zipfile
from pathlib import Path

try:
    import pandas as pd
except ImportError as e:
    sys.exit(f"[ERRO] Instale as libs: pip install pandas pyarrow\n{e}")

sys.path.insert(0, str(Path(__file__).resolve().parent))
from db import conectar  # reaproveita wallet + senhas de .claude/oci.secrets

FTP_HOST = "ftp.datasus.gov.br"
BASE = "/territorio/tabelas"
ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw" / "TERRITORIO"
PROC = ROOT / "data" / "processed" / "TERRITORIO"

# A Base Territorial e nacional. Carregamos o Brasil inteiro, nao so SP: o SIH de
# SP recebe residentes de outros estados (2.827 municipios fora de SP aparecem em
# slv_municipio) e o fluxo intermunicipal depende de saber a regiao deles tambem.


def mais_recente(ftp: ftplib.FTP) -> tuple[str, str]:
    """Acha o zip mais novo em /territorio/tabelas/<ano>/. Retorna (caminho, nome)."""
    anos = sorted((a for a in ftp.nlst(BASE) if re.fullmatch(r"\d{4}", Path(a).name)),
                  key=lambda a: Path(a).name, reverse=True)
    for ano in anos:
        dir_ano = f"{BASE}/{Path(ano).name}"
        zips = sorted(n for n in ftp.nlst(dir_ano) if n.lower().endswith(".zip"))
        if zips:
            # nomes comecam com o mes: 02-, 04-, 06- ... o maior e o mais recente
            nome = Path(zips[-1]).name
            return f"{dir_ano}/{nome}", nome
    sys.exit("[ERRO] nenhum zip encontrado em /territorio/tabelas/")


def baixar(destino_dir: Path) -> Path:
    socket.setdefaulttimeout(60)
    ftp = ftplib.FTP(FTP_HOST); ftp.login(); ftp.set_pasv(True)
    try:
        remoto, nome = mais_recente(ftp)
        destino_dir.mkdir(parents=True, exist_ok=True)
        destino = destino_dir / nome.split("-", 1)[-1]
        print(f"baixando {remoto}")
        with open(destino, "wb") as f:
            ftp.retrbinary(f"RETR {remoto}", f.write)
        print(f"  ok  {destino}  ({destino.stat().st_size/1e6:.1f} MB)")
        return destino
    finally:
        ftp.quit()


def extrair(zip_path: Path) -> pd.DataFrame:
    """Le os tres CSV de dentro do zip e devolve um municipio por linha.

    Cuidado com o formato: rl_municip_regsaud e tb_municip vem com ';' e
    tb_regsaud com ','. Todos sao UTF-8, apesar de o resto do DATASUS ser
    latin-1. As coordenadas de tb_municip usam virgula decimal."""
    with zipfile.ZipFile(zip_path) as z:
        rl = pd.read_csv(io.BytesIO(z.read("rl_municip_regsaud.csv")),
                         sep=";", dtype=str, encoding="utf-8")
        tb = pd.read_csv(io.BytesIO(z.read("tb_regsaud.csv")),
                         sep=",", dtype=str, encoding="utf-8")
        mun = pd.read_csv(io.BytesIO(z.read("tb_municip.csv")),
                          sep=";", dtype=str, encoding="utf-8",
                          usecols=["CO_MUNICIP", "DS_NOME", "UF", "CO_STATUS",
                                   "NU_LATITUD", "NU_LONGIT"])

    df = rl.merge(tb[["CO_REGSAUD", "CO_STATUS", "DS_NOME"]], on="CO_REGSAUD", how="left")
    orfaos = df.DS_NOME.isna().sum()
    if orfaos:
        print(f"  aviso: {orfaos} municipios com regiao sem nome em tb_regsaud")

    # O sufixo ' - UF' repete a UF em todo nome ("Sorocaba - SP"). Fica ruidoso num
    # painel que ja e so de SP e atrapalha o Select AI a casar o que o gestor digita.
    df["nome_regiao"] = df.DS_NOME.str.replace(r"\s*-\s*[A-Z]{2}$", "", regex=True).str.strip()
    df["uf_ibge"] = df.CO_MUNICIP.str[:2]
    df = df.rename(columns={"CO_MUNICIP": "cod_municipio", "CO_REGSAUD": "cod_regiao_saude"})
    df = df[["cod_municipio", "cod_regiao_saude", "nome_regiao", "uf_ibge", "CO_STATUS"]]

    # tb_municip traz TODOS os municipios, inclusive extintos e os placeholders
    # "Municipio Ignorado" que o DATASUS usa quando a origem nao informa. Eles nao
    # tem regiao de saude, mas aparecem no SIH e precisam de nome para nao virarem
    # um codigo solto na resposta do Select AI. Por isso o merge e a esquerda de mun.
    mun = mun.rename(columns={"CO_MUNICIP": "cod_municipio", "DS_NOME": "nome_municipio",
                              "UF": "uf", "CO_STATUS": "status_municipio"})
    for c in ("NU_LATITUD", "NU_LONGIT"):
        mun[c] = pd.to_numeric(mun[c].str.replace(",", ".", regex=False), errors="coerce")
    mun = mun.rename(columns={"NU_LATITUD": "latitude", "NU_LONGIT": "longitude"})

    return mun.merge(df.drop(columns=["uf_ibge"]), on="cod_municipio", how="left")


def conferir(df: pd.DataFrame) -> None:
    sp = df[df.uf == "SP"]
    com_reg = df.cod_regiao_saude.notna()
    print(f"\n  Brasil: {len(df):,} municipios | {com_reg.sum():,} com regiao "
          f"| {df.cod_regiao_saude.nunique()} regioes")
    print(f"  SP:     {len(sp):,} municipios | {sp.cod_regiao_saude.notna().sum():,} com regiao "
          f"| {sp.cod_regiao_saude.nunique()} regioes")
    print(f"  sem coordenada: {df.latitude.isna().sum():,}")
    dup = df.cod_municipio.duplicated().sum()
    print(f"  municipios repetidos: {dup}  (esperado 0)")
    if dup:
        sys.exit("[ERRO] de/para ambiguo — a Base Territorial nao deveria repetir municipio")
    sp_ativos = sp[sp.status_municipio == "ATIVO"]
    if len(sp_ativos) != 645:
        print(f"  aviso: SP tem 645 municipios ativos, o arquivo trouxe {len(sp_ativos)}")


def carregar(df: pd.DataFrame) -> None:
    """Cria SLV_REGIAO_SAUDE e preenche SLV_MUNICIPIO. Idempotente."""
    con = conectar("silver")
    cur = con.cursor()
    # O workload DW liga DML paralelo por padrao. Depois de um DELETE paralelo a
    # sessao nao pode reler nem regravar a mesma tabela antes do commit (ORA-12838),
    # e este carregador faz DELETE seguido de INSERT. Sao milhares de linhas, nao
    # milhoes: serial resolve e nao custa nada.
    cur.execute("ALTER SESSION DISABLE PARALLEL DML")

    cur.execute("SELECT COUNT(*) FROM user_tables WHERE table_name = 'SLV_REGIAO_SAUDE'")
    if cur.fetchone()[0]:
        cur.execute("DELETE FROM slv_regiao_saude")
    else:
        cur.execute("""
            CREATE TABLE slv_regiao_saude (
              cod_regiao_saude  VARCHAR2(5) PRIMARY KEY,
              nome_regiao_saude VARCHAR2(60) NOT NULL,
              uf                VARCHAR2(2),
              ativa             CHAR(1)
            )""")
        cur.execute("GRANT SELECT ON slv_regiao_saude TO gold")

    reg = df[df.cod_regiao_saude.notna()]
    regioes = (reg.groupby(["cod_regiao_saude", "nome_regiao", "uf", "CO_STATUS"])
                  .size().reset_index())
    cur.executemany(
        "INSERT INTO slv_regiao_saude VALUES (:1, :2, :3, :4)",
        [(r.cod_regiao_saude, r.nome_regiao, r.uf, "S" if r.CO_STATUS == "S" else "N")
         for r in regioes.itertuples()])
    print(f"  slv_regiao_saude: {len(regioes)} regioes")

    # colunas que nao existiam na criacao original da Silver
    novas = {"COD_REGIAO_SAUDE": "VARCHAR2(5)", "NOME_MUNICIPIO": "VARCHAR2(60)",
             "LATITUDE": "NUMBER(10,6)", "LONGITUDE": "NUMBER(10,6)"}
    cur.execute("SELECT column_name FROM user_tab_columns WHERE table_name = 'SLV_MUNICIPIO'")
    existentes = {r[0] for r in cur.fetchall()}
    for col, tipo in novas.items():
        if col not in existentes:
            cur.execute(f"ALTER TABLE slv_municipio ADD ({col} {tipo})")

    # tabela de apoio: um MERGE por linha custaria 5.572 round-trips
    cur.execute("SELECT COUNT(*) FROM user_tables WHERE table_name = 'TMP_TERRITORIO'")
    if cur.fetchone()[0]:
        cur.execute("TRUNCATE TABLE tmp_territorio")
    else:
        cur.execute("""CREATE TABLE tmp_territorio (
                         cod_municipio    NUMBER(6),
                         nome_municipio   VARCHAR2(60),
                         cod_regiao_saude VARCHAR2(5),
                         latitude         NUMBER(10,6),
                         longitude        NUMBER(10,6))""")
    cur.executemany(
        "INSERT INTO tmp_territorio VALUES (:1, :2, :3, :4, :5)",
        [(int(r.cod_municipio), r.nome_municipio,
          None if pd.isna(r.cod_regiao_saude) else r.cod_regiao_saude,
          None if pd.isna(r.latitude) else float(r.latitude),
          None if pd.isna(r.longitude) else float(r.longitude))
         for r in df.itertuples()])

    cur.execute("""
        MERGE INTO slv_municipio m
        USING (SELECT t.cod_municipio, t.nome_municipio, t.cod_regiao_saude,
                      t.latitude, t.longitude, r.nome_regiao_saude
                 FROM tmp_territorio t
                 LEFT JOIN slv_regiao_saude r ON r.cod_regiao_saude = t.cod_regiao_saude) s
           ON (m.cod_municipio = s.cod_municipio)
         WHEN MATCHED THEN UPDATE SET m.nome_municipio   = s.nome_municipio,
                                      m.cod_regiao_saude = s.cod_regiao_saude,
                                      m.regiao_saude     = s.nome_regiao_saude,
                                      m.latitude         = s.latitude,
                                      m.longitude        = s.longitude""")
    print(f"  slv_municipio atualizados: {cur.rowcount}")
    cur.execute("DROP TABLE tmp_territorio PURGE")
    con.commit()

    for rotulo, filtro in (("SP", "WHERE uf = 'SP'"), ("BR", "")):
        cur.execute(f"""SELECT COUNT(*), COUNT(nome_municipio), COUNT(regiao_saude)
                          FROM slv_municipio {filtro}""")
        tot, nome, reg_ = cur.fetchone()
        print(f"  cobertura {rotulo}: {nome}/{tot} com nome, {reg_}/{tot} com regiao de saude")
    con.close()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--zip", help="usa um zip ja baixado em vez de ir no FTP")
    ap.add_argument("--so-baixar", action="store_true", help="nao carrega no banco")
    a = ap.parse_args()

    zip_path = Path(a.zip) if a.zip else baixar(RAW)
    df = extrair(zip_path)
    conferir(df)

    PROC.mkdir(parents=True, exist_ok=True)
    saida = PROC / "territorio.parquet"
    df.to_parquet(saida, index=False)
    print(f"  parquet: {saida}")

    if not a.so_baixar:
        print("\ncarregando no Autonomous Database")
        carregar(df)
    print("\nok")


if __name__ == "__main__":
    main()
