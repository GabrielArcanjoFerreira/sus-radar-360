# SUS Radar 360

Painel inteligente de monitoramento de **acesso hospitalar, vulnerabilidade social e risco epidemiológico**, sobre dados públicos do DATASUS.

Challenge Oracle × FIAP 2026 · Grupo **GreatMinds** · Turma 1TSCOA · Entrega final out/2026.
MVP restrito a **São Paulo**, agregado por região de saúde.

> **Pergunta central:** quais municípios ou regiões apresentam maior risco de sobrecarga no sistema de saúde, considerando internações, estrutura hospitalar, perfil social, riscos epidemiológicos, natalidade e mortalidade?

## Estado

| Etapa | Situação |
|---|---|
| Definição das bases | pronto |
| Download e conversão | **33 arquivos · 9.045.693 registros · 417 MB** |
| Object Storage | **35 objetos no bucket `datasus-raw`** |
| Autonomous Database | **provisionado** — Oracle 19c DW, Always Free |
| Bronze | **5 tabelas · 9.045.693 linhas** |
| Silver | **6 tabelas + 6 domínios · sem perda de linhas** |
| Gold | **`gld_painel_assistencial` · 14.789 linhas** |
| Power BI | conectável em `GOLD.VW_PAINEL_ASSISTENCIAL` |
| Região de saúde no IPA | **bloqueado** — falta a tabela oficial do DATASUS |

## Estrutura

```
data/{raw,processed}    dados — fora do git
scripts/                ingestão, upload, geração de DDL, execução de SQL
sql/00_setup/           usuários das camadas e credencial DBMS_CLOUD
sql/01_bronze/          external tables sobre os Parquet
sql/02_silver/          tratamento, domínios e dimensões
sql/03_gold/            tabela do painel e rotina de carga
docs/                   documentação técnica
notebooks/              exploração e validação
.claude/                contexto do projeto, skills e agents de OCI
```

## Pipeline, em ordem

```bash
python3 -m venv .venv
.venv/bin/pip install datasus-dbc dbfread pandas pyarrow oracledb oci-cli

# 1. baixar do DATASUS (longo; confira o FTP antes — ver docs/ingestao.md)
.venv/bin/python scripts/download_files.py --uf SP --cnes-mes 202607 \
    --sim-anos 2021 2022 2023 2024 --sinasc-anos 2020 2021 2022
.venv/bin/python scripts/catalogo.py

# 2. subir para o OCI Object Storage
./scripts/upload_oci.sh
./scripts/upload_oci.sh --check

# 3. Bronze — external tables e materialização
.venv/bin/python scripts/gen_external_tables.py
.venv/bin/python scripts/db.py -u bronze sql/01_bronze/0*.sql
.venv/bin/python scripts/materializar_bronze.py

# 4. Silver
.venv/bin/python scripts/db.py -u silver sql/02_silver/*.sql

# 5. Gold
.venv/bin/python scripts/db.py -u gold sql/03_gold/*.sql
```

Recarregar só a Gold, depois que a Silver mudar:

```sql
DECLARE n NUMBER; BEGIN prc_carga_painel_assistencial(NULL, n); END;
/
```

## Scripts

| Script | O que faz |
|---|---|
| `download_files.py` | baixa DBC do FTP do DATASUS e converte para Parquet |
| `catalogo.py` | inventaria os Parquet → `docs/catalogo-bases.md` |
| `upload_oci.sh` | cria o bucket e sobe os Parquet; `--check` compara local × bucket |
| `gen_external_tables.py` | gera o DDL da Bronze a partir do schema real dos Parquet |
| `materializar_bronze.py` | carrega as tabelas físicas com `COPY_DATA` e retentativa |
| `criar_credencial.py` | cria a credencial DBMS_CLOUD sem expor a chave |
| `db.py` | executa SQL no ADB via wallet, mascarando segredos |
| `gen_dicionario.py` | gera o dicionário de dados a partir do banco |

## Documentação

Índice completo em **[docs/README.md](docs/README.md)**.

| Documento | Conteúdo |
|---|---|
| [arquitetura.md](docs/arquitetura.md) | fluxo de ponta a ponta, camadas, infra OCI, segurança |
| [dicionario.md](docs/dicionario.md) | toda coluna de Bronze, Silver e Gold — gerado do banco |
| [ingestao.md](docs/ingestao.md) | como reproduzir a carga e as decisões tomadas |
| [catalogo-bases.md](docs/catalogo-bases.md) | inventário das bases — gerado |
| [gold.md](docs/gold.md) | fórmulas do IPA, limiares de risco e ressalvas |
| [powerbi.md](docs/powerbi.md) | conectar o Power BI, passo a passo |
| [problemas-conhecidos.md](docs/problemas-conhecidos.md) | defeitos dos dados e armadilhas de ferramenta |
| `acesso.md` | credenciais — **fora do git** |

## Bases

| Sistema | Grupo | Conteúdo | Competências |
|---|---|---|---|
| SIHSUS | `RD` | internações (AIH) | 2024-06 a 2026-05 |
| CNES | `LT` / `ST` | leitos e estabelecimentos | 2026-07 |
| SIM | `DO` | óbitos | 2021 a 2024 |
| SINASC | `DN` | nascidos vivos | 2020 a 2022 |
| IBGE | — | população, Censo, PIB | pendente |

## O que ainda bloqueia

**O de/para município → região de saúde não existe.** Todo o painel agrega por região de saúde, e nenhuma base baixada traz isso de forma usável: o SIH só tem código IBGE de município, e o `REGSAUDE` do CNES é texto livre com 56% em branco e 291 valores distintos — só 58 dos 645 municípios têm valor consistente. Precisa vir da tabela oficial do DATASUS (Modalidade *Documentação* na Transferência de Arquivos). Sem ela não existe `VW_IPA_REGIAO`.

---

*Ana Karen da Silva Costa · Gabriel Arcanjo dos Santos · Guilherme Ruivo Talamonti · Nathan de Oliveira Silva · Ryan Coutinho Oliveira*
