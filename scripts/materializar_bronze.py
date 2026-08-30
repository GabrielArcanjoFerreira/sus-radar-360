#!/usr/bin/env python3
"""
Materializa a camada Bronze em tabelas FISICAS, carregando arquivo por arquivo
com DBMS_CLOUD.COPY_DATA e retentativa.

Por que nao ficar so na External Table: no ADB Always Free o acesso ao Object
Storage se mostrou intermitente (KUP-13016 HTTP-404 em arquivos comprovadamente
legiveis por GET_OBJECT), e a mesma tabela falha e funciona em chamadas seguidas.
Alem disso External Table rele o bucket a cada consulta — inviavel para o APEX,
que o deck promete responder em menos de 15s.

As External Tables continuam existindo como BRZ_*_EXT (contrato/documentacao);
o que Silver consome sao as fisicas BRZ_*.

  .venv/bin/python scripts/materializar_bronze.py
  .venv/bin/python scripts/materializar_bronze.py --tabela BRZ_SIH_RD
"""
from __future__ import annotations
import argparse, importlib.util, re, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("db", ROOT / "scripts" / "db.py")
db = importlib.util.module_from_spec(spec); spec.loader.exec_module(db)

BASE = "https://objectstorage.us-ashburn-1.oraclecloud.com/n/idnxdejel4kp/b/datasus-raw/o/"
CRED = "OCI$RESOURCE_PRINCIPAL"

TABELAS = {
    "BRZ_SIH_RD":    ("SIHSUS", "RDSP*", "processed/sihsus/",  "02_brz_sih_rd.sql"),
    "BRZ_CNES_LT":   ("CNES",   "LTSP*", "processed/cnes/",    "03_brz_cnes_lt.sql"),
    "BRZ_CNES_ST":   ("CNES",   "STSP*", "processed/cnes/",    "04_brz_cnes_st.sql"),
    "BRZ_SIM_DO":    ("SIM",    "DOSP*", "processed/sim/",     "05_brz_sim_do.sql"),
    "BRZ_SINASC_DN": ("SINASC", "DNSP*", "processed/sinasc/",  "06_brz_sinasc_dn.sql"),
}


def column_list(arquivo_sql: str) -> str:
    t = (ROOT / "sql" / "01_bronze" / arquivo_sql).read_text()
    return t[t.index("column_list     => '") + 20 : t.rindex("');")]


def ddl_fisica(tabela: str, cols: str) -> str:
    # column_list vira definicao de tabela: tira comentarios e normaliza virgulas
    linhas = []
    for l in cols.splitlines():
        l = re.sub(r"--.*$", "", l).strip().rstrip(",")
        if l:
            linhas.append("  " + l)
    return f"CREATE TABLE {tabela} (\n" + ",\n".join(linhas) + "\n)"


def carregar(cur, tabela: str, uri: str, cols: str, tentativas: int = 4) -> int:
    for t in range(1, tentativas + 1):
        try:
            cur.execute("""BEGIN DBMS_CLOUD.COPY_DATA(table_name=>:t, credential_name=>:c,
                           file_uri_list=>:u, format=>JSON_OBJECT('type' VALUE 'parquet')); END;""",
                        t=tabela, c=CRED, u=uri)
            return 0
        except Exception as e:
            msg = str(e).splitlines()[0]
            if t == tentativas:
                print(f"      FALHOU apos {tentativas} tentativas: {msg[:90]}")
                return 1
            time.sleep(5 * t)
    return 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tabela", action="append", help="so estas tabelas")
    a = ap.parse_args()
    alvos = a.tabela or list(TABELAS)

    con = db.conectar("bronze")
    falhas_totais = 0
    try:
        with con.cursor() as cur:
            cur.execute("ALTER SESSION DISABLE PARALLEL QUERY")
            for tabela in alvos:
                sistema, glob, prefixo, sql = TABELAS[tabela]
                cols = column_list(sql)
                arqs = sorted(p.stem for p in (ROOT / "data" / "processed" / sistema).glob(f"{glob}.parquet"))
                print(f"\n=== {tabela} ({len(arqs)} arquivos) ===")

                # a External Table original vira _EXT; a fisica assume o nome
                cur.execute(f"BEGIN EXECUTE IMMEDIATE 'DROP TABLE {tabela} PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;")
                cur.execute(ddl_fisica(tabela, cols))
                con.commit()

                falhas = 0
                t0 = time.time()
                for i, arq in enumerate(arqs, 1):
                    falhas += carregar(cur, tabela, f"{BASE}{prefixo}{arq}.parquet", cols)
                    con.commit()
                    if i % 6 == 0 or i == len(arqs):
                        cur.execute(f"SELECT COUNT(*) FROM {tabela}")
                        print(f"  {i:2}/{len(arqs)}  {cur.fetchone()[0]:>10,} linhas  ({time.time()-t0:.0f}s)")
                cur.execute(f"SELECT COUNT(*) FROM {tabela}")
                total = cur.fetchone()[0]
                print(f"  -> {total:,} linhas, {falhas} arquivo(s) com falha")
                falhas_totais += falhas
    finally:
        con.close()
    if falhas_totais:
        sys.exit(f"\n{falhas_totais} arquivo(s) nao carregaram")
    print("\nBronze materializada sem falhas")


if __name__ == "__main__":
    main()
