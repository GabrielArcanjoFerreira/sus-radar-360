#!/usr/bin/env python3
"""
Inventario das bases baixadas. Le os Parquet de data/processed/ e gera:
    docs/catalogo-bases.md   — catalogo legivel, versionado
    data/catalogo.csv        — mesma informacao, tabular

Roda sem argumento:  .venv/bin/python scripts/catalogo.py
"""
from __future__ import annotations
from pathlib import Path
import re, sys
import pandas as pd
import pyarrow.parquet as pq

ROOT = Path(__file__).resolve().parent.parent
PROC = ROOT / "data" / "processed"
RAW = ROOT / "data" / "raw"

# Como ler a competencia do nome do arquivo, por sistema.
PADROES = {
    "SIHSUS": (r"^RD..(\d{2})(\d{2})$", "mensal"),
    "CNES":   (r"^(?:LT|ST)..(\d{2})(\d{2})$", "mensal"),
    "SIM":    (r"^DO..(\d{4})$", "anual"),
    "SINASC": (r"^DN..(\d{4})$", "anual"),
}

DESCRICAO = {
    ("SIHSUS", "RD"): "AIH Reduzida — 1 linha = 1 internacao",
    ("CNES", "LT"):   "Leitos por estabelecimento e tipo",
    ("CNES", "ST"):   "Estabelecimentos de saude (cadastro)",
    ("SIM", "DO"):    "Declaracao de Obito — 1 linha = 1 obito",
    ("SINASC", "DN"): "Declaracao de Nascido Vivo — 1 linha = 1 nascimento",
}


def competencia(sistema: str, stem: str) -> str:
    padrao, periodicidade = PADROES.get(sistema, (None, ""))
    if not padrao:
        return stem
    m = re.match(padrao, stem)
    if not m:
        return stem
    if periodicidade == "mensal":
        return f"20{m.group(1)}-{m.group(2)}"
    return m.group(1)


def coletar() -> pd.DataFrame:
    linhas = []
    for pqt in sorted(PROC.rglob("*.parquet")):
        sistema = pqt.parent.name
        md = pq.ParquetFile(pqt).metadata
        dbc = RAW / sistema / (pqt.stem + ".dbc")
        linhas.append({
            "sistema": sistema,
            "grupo": pqt.stem[:2],
            "arquivo": pqt.stem,
            "competencia": competencia(sistema, pqt.stem),
            "linhas": md.num_rows,
            "colunas": md.num_columns,
            "mb_parquet": round(pqt.stat().st_size / 1e6, 1),
            "mb_dbc": round(dbc.stat().st_size / 1e6, 1) if dbc.exists() else None,
        })
    if not linhas:
        sys.exit(f"[ERRO] nenhum parquet em {PROC}")
    return pd.DataFrame(linhas).sort_values(["sistema", "arquivo"]).reset_index(drop=True)


def markdown(df: pd.DataFrame) -> str:
    t = ["# Catalogo das bases baixadas",
         "",
         "> Gerado por `scripts/catalogo.py` a partir de `data/processed/`. Nao editar a mao.",
         "",
         "## Resumo por base", ""]

    resumo = (df.groupby(["sistema", "grupo"])
                .agg(arquivos=("arquivo", "count"),
                     de=("competencia", "min"), ate=("competencia", "max"),
                     linhas=("linhas", "sum"), colunas=("colunas", "max"),
                     mb_parquet=("mb_parquet", "sum"), mb_dbc=("mb_dbc", "sum"))
                .reset_index())

    t.append("| Sistema | Grupo | Conteudo | Arquivos | Periodo | Linhas | Colunas | Parquet | DBC |")
    t.append("|---|---|---|---:|---|---:|---:|---:|---:|")
    for r in resumo.itertuples():
        desc = DESCRICAO.get((r.sistema, r.grupo), "")
        periodo = r.de if r.de == r.ate else f"{r.de} a {r.ate}"
        t.append(f"| **{r.sistema}** | `{r.grupo}` | {desc} | {r.arquivos} | {periodo} | "
                 f"{r.linhas:,} | {r.colunas} | {r.mb_parquet:,.0f} MB | {r.mb_dbc:,.0f} MB |")

    t += ["",
          f"**Total:** {len(df)} arquivos · {df.linhas.sum():,} registros · "
          f"{df.mb_parquet.sum():,.0f} MB em Parquet "
          f"(de {df.mb_dbc.sum():,.0f} MB de DBC bruto).",
          "", "## Detalhe por arquivo", ""]

    for sistema, bloco in df.groupby("sistema"):
        t += [f"### {sistema}", "",
              "| Arquivo | Competencia | Linhas | Colunas | Parquet |",
              "|---|---|---:|---:|---:|"]
        for r in bloco.itertuples():
            t.append(f"| `{r.arquivo}` | {r.competencia} | {r.linhas:,} | {r.colunas} | {r.mb_parquet} MB |")
        t.append("")

    t += ["## Colunas por base", ""]
    for (sistema, grupo), bloco in df.groupby(["sistema", "grupo"]):
        amostra = PROC / sistema / (bloco.arquivo.iloc[0] + ".parquet")
        cols = pq.ParquetFile(amostra).schema_arrow.names
        t += [f"<details><summary><b>{sistema} {grupo}</b> — {len(cols)} colunas</summary>", "",
              "```", ", ".join(cols), "```", "", "</details>", ""]
    return "\n".join(t)


def main():
    df = coletar()
    (ROOT / "docs").mkdir(exist_ok=True)
    (ROOT / "docs" / "catalogo-bases.md").write_text(markdown(df), encoding="utf-8")
    df.to_csv(ROOT / "data" / "catalogo.csv", index=False)
    print(df.to_string(index=False))
    print(f"\n{len(df)} arquivos · {df.linhas.sum():,} registros · {df.mb_parquet.sum():,.0f} MB")
    print("→ docs/catalogo-bases.md e data/catalogo.csv")


if __name__ == "__main__":
    main()
