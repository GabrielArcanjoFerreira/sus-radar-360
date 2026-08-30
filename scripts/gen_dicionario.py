#!/usr/bin/env python3
"""
Gera docs/dicionario.md lendo o dicionario de dados do Autonomous Database.

Percorre BRONZE, SILVER e GOLD, coleta colunas, tipos, nulidade e contagem de
linhas, e cruza com as descricoes de negocio mantidas aqui neste arquivo.

  .venv/bin/python scripts/gen_dicionario.py
"""
from __future__ import annotations
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("db", ROOT / "scripts" / "db.py")
db = importlib.util.module_from_spec(spec); spec.loader.exec_module(db)

CAMADAS = ["BRONZE", "SILVER", "GOLD"]

TABELA_DESC = {
    "BRZ_SIH_RD":      "SIHSUS RD cru — 1 linha = 1 AIH (internacao paga pelo SUS)",
    "BRZ_CNES_LT":     "CNES LT cru — leitos por estabelecimento e tipo",
    "BRZ_CNES_ST":     "CNES ST cru — cadastro de estabelecimentos",
    "BRZ_SIM_DO":      "SIM DO cru — declaracoes de obito",
    "BRZ_SINASC_DN":   "SINASC DN cru — declaracoes de nascido vivo",
    "SLV_INTERNACAO":  "internacoes tratadas: datas em DATE, idade em anos, codigos resolvidos",
    "SLV_LEITO":       "leitos tratados, por estabelecimento",
    "SLV_ESTABELECIMENTO": "estabelecimentos tratados",
    "SLV_OBITO":       "obitos tratados: data DDMMYYYY convertida, idade decodificada",
    "SLV_NASCIMENTO":  "nascimentos tratados, com indicadores derivados",
    "SLV_MUNICIPIO":   "dimensao territorial — regiao_saude PENDENTE",
    "GLD_PAINEL_ASSISTENCIAL": "fato do painel: ano x mes x estabelecimento, com IPA e risco",
    "GLD_FAIXA_RISCO": "limiares de classificacao de risco",
}

# Colunas cujo significado nao e obvio pelo nome.
COLUNA_DESC = {
    # SIH cru
    "N_AIH": "numero da AIH", "MUNIC_RES": "municipio de RESIDENCIA (IBGE)",
    "MUNIC_MOV": "municipio de INTERNACAO (IBGE)", "DT_INTER": "data de admissao (AAAAMMDD)",
    "DIAS_PERM": "dias de permanencia", "DIAG_PRINC": "CID-10 principal",
    "PROC_REA": "procedimento SIGTAP realizado", "ESPEC": "especialidade do leito",
    "CAR_INT": "carater da internacao", "COMPLEX": "complexidade",
    "COD_IDADE": "unidade de IDADE: 2=dias 3=meses 4=anos 5=100+anos",
    "SEXO": "no SIH: 1=M, 3=F (difere do SIM)", "UTI_MES_TO": "diarias de UTI no mes",
    "VAL_TOT": "valor total faturado", "ANO_CMPT": "ano da competencia de faturamento",
    "MES_CMPT": "mes da competencia", "FONTE_ORC": "fonte do recurso; so existe de 2025-03 em diante",
    # CNES
    "QT_EXIST": "leitos existentes", "QT_SUS": "leitos SUS", "QT_CONTR": "leitos contratados",
    "CODUFMUN": "municipio do estabelecimento (IBGE)", "TP_LEITO": "tipo de leito",
    "TP_UNID": "tipo de unidade", "VINC_SUS": "atende SUS", "NAT_JUR": "natureza juridica",
    "REGSAUDE": "NAO CONFIAVEL: texto livre, 56% em branco, 291 valores distintos",
    # SIM / SINASC
    "CAUSABAS": "CID-10 da causa basica", "CODMUNRES": "municipio de residencia (IBGE)",
    "DTOBITO": "data do obito (DDMMAAAA)", "LOCOCOR": "local de ocorrencia",
    "IDADE": "no SIM vem codificada: 1o digito = unidade",
    "DTNASC": "data de nascimento (DDMMAAAA)", "PESO": "peso ao nascer em gramas",
    "GESTACAO": "faixa de semanas de gestacao", "CONSULTAS": "faixa de consultas de pre-natal",
    "APGAR5": "Apgar no 5o minuto", "IDADEMAE": "idade da mae",
    # Silver
    "idade_anos": "idade normalizada para anos, via COD_IDADE",
    "internou_fora_do_municipio": "1 quando residencia != internacao — insumo do IPA",
    "obito": "flag 0/1", "usou_uti": "flag 0/1",
    "cid_capitulo": "primeira letra do CID-10",
    "baixo_peso": "1 quando peso < 2500g", "prematuro": "1 quando gestacao < 37 semanas",
    "sem_prenatal": "1 quando nenhuma consulta", "mae_adolescente": "1 quando mae < 20 anos",
    "regsaude_cnes_nao_confiavel": "mantido so como evidencia; nao usar para agregar",
    "regiao_saude": "PENDENTE — depende da tabela oficial do DATASUS",
    # Gold
    "ipa_percentual": "total_dias_permanencia / (capacidade_leitos * 30) * 100",
    "permanencia_media": "total_dias_permanencia / internacoes",
    "risco_assistencial": "classificacao lida de GLD_FAIXA_RISCO",
    "capacidade_leitos": "soma de QT_EXIST do CNES para o estabelecimento",
    "id_municipio_estabelecimento_aih": "municipio do estabelecimento (= MUNIC_MOV)",
}


def coletar(con, schema: str) -> list[dict]:
    saida = []
    with con.cursor() as cur:
        cur.execute("""SELECT table_name FROM all_tables
                        WHERE owner = :s AND table_name NOT LIKE 'COPY$%'
                        ORDER BY table_name""", s=schema)
        tabelas = [r[0] for r in cur]
        for t in tabelas:
            cur.execute(f"SELECT COUNT(*) FROM {schema}.{t}")
            n = cur.fetchone()[0]
            cur.execute("""SELECT column_name, data_type, data_length, data_precision,
                                  data_scale, nullable
                             FROM all_tab_columns
                            WHERE owner = :s AND table_name = :t
                            ORDER BY column_id""", s=schema, t=t)
            cols = cur.fetchall()
            saida.append({"tabela": t, "linhas": n, "colunas": cols})
    return saida


def tipo(dt, ln, p, s) -> str:
    if dt in ("VARCHAR2", "CHAR"):
        return f"{dt}({ln})"
    if dt == "NUMBER":
        if p and s:
            return f"NUMBER({p},{s})"
        if p:
            return f"NUMBER({p})"
        return "NUMBER"
    return dt


def main():
    linhas = ["# Dicionario de dados", "",
              "> Gerado por `scripts/gen_dicionario.py` a partir do Autonomous Database.",
              "> Nao editar a mao — as descricoes de negocio ficam no proprio script.", ""]

    for schema in CAMADAS:
        con = db.conectar("ADMIN")
        dados = coletar(con, schema)
        con.close()
        if not dados:
            continue
        total = sum(d["linhas"] for d in dados)
        linhas += [f"## {schema}", "",
                   f"{len(dados)} tabelas, {total:,} linhas.".replace(",", "."), ""]
        for d in dados:
            desc = TABELA_DESC.get(d["tabela"], "")
            linhas += [f"### `{d['tabela']}`", ""]
            if desc:
                linhas += [desc, ""]
            linhas += [f"**{d['linhas']:,} linhas · {len(d['colunas'])} colunas**".replace(",", "."), "",
                       "| Coluna | Tipo | Nulo | Significado |", "|---|---|---|---|"]
            for c in d["colunas"]:
                nome, dt, ln, p, s, nul = c
                obs = COLUNA_DESC.get(nome, COLUNA_DESC.get(nome.lower(), ""))
                linhas.append(f"| `{nome}` | {tipo(dt,ln,p,s)} | {'sim' if nul=='Y' else 'nao'} | {obs} |")
            linhas.append("")

    (ROOT / "docs" / "dicionario.md").write_text("\n".join(linhas), encoding="utf-8")
    print(f"docs/dicionario.md — {len(linhas)} linhas")


if __name__ == "__main__":
    main()
