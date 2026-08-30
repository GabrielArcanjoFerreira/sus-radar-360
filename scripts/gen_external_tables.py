#!/usr/bin/env python3
"""
Gera o DDL das External Tables (camada Bronze) a partir dos Parquet locais.

Por que gerar em vez de inferir: DBMS_CLOUD.CREATE_EXTERNAL_TABLE com
'schema' VALUE 'first' le o layout do PRIMEIRO arquivo do file_uri_list e aplica
aos demais. O SIH tem 113 colunas ate 2025-02 e 114 a partir de 2025-03
(FONTE_ORC) — inferir faria a coluna sumir em silencio. Aqui a lista de colunas e
a UNIAO de todas as competencias, com o tamanho real de cada campo.

Uso:  .venv/bin/python scripts/gen_external_tables.py
Saida: sql/01_bronze/*.sql
"""
from __future__ import annotations
from pathlib import Path
import pyarrow.parquet as pq
import pyarrow.compute as pc

ROOT = Path(__file__).resolve().parent.parent
PROC = ROOT / "data" / "processed"
OUT = ROOT / "sql" / "01_bronze"

# tabela Bronze -> (sistema, glob dos parquet, prefixo no bucket, descricao)
TABELAS = {
    "BRZ_SIH_RD":   ("SIHSUS", "RDSP*", "processed/sihsus/",  "SIHSUS RD — AIH Reduzida, 1 linha = 1 internacao"),
    "BRZ_CNES_LT":  ("CNES",   "LTSP*", "processed/cnes/LT",  "CNES LT — leitos por estabelecimento e tipo"),
    "BRZ_CNES_ST":  ("CNES",   "STSP*", "processed/cnes/ST",  "CNES ST — cadastro de estabelecimentos"),
    "BRZ_SIM_DO":   ("SIM",    "DOSP*", "processed/sim/",     "SIM DO — declaracoes de obito"),
    "BRZ_SINASC_DN":("SINASC", "DNSP*", "processed/sinasc/",  "SINASC DN — declaracoes de nascido vivo"),
}


def tipo_oracle(arrow_tipo: str, tam: int | None) -> str:
    if arrow_tipo == "string":
        # folga de 20% sobre o maior valor observado, minimo 10, teto 4000
        n = max(10, min(4000, int((tam or 1) * 1.2) + 1))
        return f"VARCHAR2({n} CHAR)"
    if arrow_tipo.startswith("int"):
        return "NUMBER(19)"
    if arrow_tipo in ("double", "float"):
        return "NUMBER"
    return "VARCHAR2(4000 CHAR)"


def perfilar(sistema: str, glob: str) -> tuple[dict, list[str], dict]:
    """Uniao das colunas de todas as competencias + tamanho maximo por coluna."""
    arqs = sorted((PROC / sistema).glob(f"{glob}.parquet"))
    if not arqs:
        return {}, [], {}
    colunas: dict[str, str] = {}   # nome -> tipo arrow (ordem de aparicao)
    tamanhos: dict[str, int] = {}
    presenca: dict[str, int] = {}  # em quantos arquivos a coluna aparece
    for a in arqs:
        t = pq.read_table(a)
        for f in t.schema:
            colunas.setdefault(f.name, str(f.type))
            presenca[f.name] = presenca.get(f.name, 0) + 1
            if str(f.type) == "string":
                m = pc.max(pc.utf8_length(t.column(f.name))).as_py()
                if m is not None:
                    tamanhos[f.name] = max(tamanhos.get(f.name, 0), m)
    parciais = [c for c, n in presenca.items() if n < len(arqs)]
    return colunas, [a.stem for a in arqs], {"tamanhos": tamanhos, "parciais": parciais,
                                             "presenca": presenca, "n_arquivos": len(arqs)}


def gerar(tabela: str) -> str:
    sistema, glob, prefixo, desc = TABELAS[tabela]
    colunas, arqs, info = perfilar(sistema, glob)
    if not colunas:
        return f"-- {tabela}: nenhum parquet encontrado em {PROC/sistema}\n"

    largura = max(len(c) for c in colunas)
    linhas = []
    for nome, tp in colunas.items():
        ora = tipo_oracle(tp, info["tamanhos"].get(nome))
        nota = ""
        if nome in info["parciais"]:
            nota = f"  -- presente em {info['presenca'][nome]}/{info['n_arquivos']} competencias"
        linhas.append(f"      {nome:<{largura}} {ora},{nota}")
    linhas[-1] = linhas[-1].replace(",  --", "   --", 1) if "--" in linhas[-1] else linhas[-1].rstrip(",")
    col_list = "\n".join(linhas)

    aviso = ""
    if info["parciais"]:
        aviso = (f"--\n-- ATENCAO: {len(info['parciais'])} coluna(s) nao existem em todas as\n"
                 f"-- competencias: {', '.join(info['parciais'])}\n"
                 f"-- Ficam NULL nos arquivos que nao as tem. E por isso que o column_list e\n"
                 f"-- declarado explicitamente em vez de inferido com 'schema' VALUE 'first'.\n")

    return f"""-- {tabela} — {desc}
-- Gerado por scripts/gen_external_tables.py. Nao editar a mao.
-- Fonte: {info['n_arquivos']} arquivo(s), {arqs[0]} a {arqs[-1]}
-- Colunas: {len(colunas)}
{aviso}--
-- Substitua <REGIAO>, <NAMESPACE> e <BUCKET> antes de rodar (veja sql/01_bronze/uris.txt).

BEGIN
  DBMS_CLOUD.CREATE_EXTERNAL_TABLE(
    table_name      => '{tabela}',
    credential_name => 'OCI$RESOURCE_PRINCIPAL',
    file_uri_list   => 'https://objectstorage.<REGIAO>.oraclecloud.com/n/<NAMESPACE>/b/<BUCKET>/o/{prefixo}*.parquet',
    format          => JSON_OBJECT('type' VALUE 'parquet'),
    column_list     => '
{col_list}
    ');
END;
/

-- A criacao NAO valida a URI: so falha na primeira consulta. Confira sempre.
SELECT COUNT(*) AS registros FROM {tabela};
"""


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for i, tabela in enumerate(TABELAS, start=2):
        arq = OUT / f"{i:02d}_{tabela.lower()}.sql"
        arq.write_text(gerar(tabela), encoding="utf-8")
        n = len(perfilar(*TABELAS[tabela][:2])[0])
        print(f"  {arq.relative_to(ROOT)}  ({n} colunas)")


if __name__ == "__main__":
    main()
