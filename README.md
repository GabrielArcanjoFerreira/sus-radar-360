# SUS Radar 360

**Painel inteligente de monitoramento de acesso hospitalar, vulnerabilidade social e risco epidemiológico**, sobre dados públicos do DATASUS.

Challenge Oracle × FIAP 2026 · Grupo **GreatMinds** · Turma 1TSCOA · Entrega final out/2026
MVP restrito a **São Paulo**, agregado por região de saúde.

> *Um radar. Um sistema. Um giro completo.*

---

## O problema

O SUS gera grandes volumes de dados públicos — internações, hospitais, população, doenças, nascimentos, óbitos — espalhados em bases diferentes e difíceis de interpretar por gestores não técnicos. Decisões sobre leitos, equipes, campanhas e investimentos ainda dependem de análise manual e cruzamentos complexos.

A pressão sobre o sistema não vem só do volume de internações: vem também de crescimento populacional, envelhecimento, baixa renda, falta de saneamento e baixa oferta hospitalar.

> **Pergunta central:** quais municípios ou regiões apresentam maior risco de sobrecarga no sistema de saúde, considerando internações, estrutura hospitalar, perfil social, riscos epidemiológicos, natalidade e mortalidade?

**Para quem:** secretarias municipais e estaduais de saúde · gestores hospitalares · áreas de planejamento · equipes de vigilância epidemiológica.

---

## Arquitetura

```
   FONTES                INGESTÃO              ORACLE AUTONOMOUS DB           CONSUMO
                                          ┌──────────────────────────┐
  SIH/SUS  ─┐                             │                          │      Power BI
  CNES     ─┤   download    OCI Object    │  BRONZE ─► SILVER ─► GOLD│ ──►  APEX
  SIM      ─┤ ──────────►   Storage    ───►  cru      tratado   painel│      Select AI
  SINASC   ─┤   DBC→Parquet  datasus-raw  │         DBMS_CLOUD/PL-SQL │
  IBGE     ─┘                             └──────────────────────────┘
```

O caminho completo: microdados em DBC no FTP do DATASUS → conversão para Parquet → **OCI Object Storage** → **External Tables** e `COPY_DATA` → modelo **medallion** no **Oracle Autonomous Database** → consumo em **Power BI**, **APEX** e **Select AI**.

### As camadas

| Camada | Schema | O que é | Conteúdo |
|---|---|---|---|
| **Bronze** | `BRONZE` | dado cru do DATASUS, tipos originais, códigos não traduzidos | 5 tabelas · 9.045.693 linhas |
| **Silver** | `SILVER` | datas em `DATE`, idade em anos, códigos resolvidos, flags derivadas | 6 tabelas + 6 domínios |
| **Gold** | `GOLD` | fato do painel, agregado por `ano × mês × estabelecimento` | 14.789 linhas |

**Bronze** guarda o dado como o DATASUS entrega. As External Tables existem e estão versionadas, mas as tabelas que a Silver consome são **físicas** — External Table relê o Object Storage a cada consulta, e o painel precisa responder em menos de 15s.

**Silver** resolve o que o dado cru não entrega: o SIH usa datas `AAAAMMDD` e o SIM/SINASC usam `DDMMAAAA`; a idade do SIH só faz sentido junto de `COD_IDADE` (dias, meses ou anos) e a do SIM vem codificada em 3 dígitos; o sexo é `1=M, 3=F` no SIH e `1=M, 2=F` no SIM. Tudo isso é normalizado aqui.

**Gold** é a tabela que alimenta o painel, com o **IPA** — Índice de Pressão Assistencial — e a classificação de risco por estabelecimento.

### O IPA

```
ipa_percentual = total_dias_permanencia / (capacidade_leitos × 30) × 100
```

Taxa de ocupação de leito no mês. Fórmula derivada por engenharia reversa da base que alimentava o painel e validada em **1281 de 1281 linhas com erro zero**. Detalhes, limiares de risco e ressalvas em [docs/gold.md](docs/gold.md).

### Tecnologias

| | |
|---|---|
| **Fonte** | DATASUS — Transferência de Arquivos (microdados DBC) |
| **Ingestão** | Python · `datasus-dbc` · `dbfread` · `pyarrow` |
| **Armazenamento** | OCI Object Storage — bucket `NoPublicAccess` |
| **Banco** | Oracle Autonomous Database 19c, workload DW, Always Free |
| **Transformação** | `DBMS_CLOUD` · SQL · PL/SQL |
| **Consumo** | Power BI · Oracle APEX · Select AI |

---

## Documentação

Índice completo em **[docs/README.md](docs/README.md)**.

| Documento | Para quê |
|---|---|
| [arquitetura.md](docs/arquitetura.md) | fluxo de ponta a ponta, camadas, infraestrutura OCI e segurança |
| [dicionario.md](docs/dicionario.md) | toda coluna de Bronze, Silver e Gold — gerado do banco |
| [ingestao.md](docs/ingestao.md) | como reproduzir a carga e as decisões tomadas |
| [catalogo-bases.md](docs/catalogo-bases.md) | inventário dos 33 arquivos baixados — gerado |
| [gold.md](docs/gold.md) | fórmulas do IPA, limiares de risco e ressalvas |
| [powerbi.md](docs/powerbi.md) | conectar o Power BI, passo a passo |
| [problemas-conhecidos.md](docs/problemas-conhecidos.md) | defeitos dos dados e armadilhas de ferramenta |

---

## As bases

| Sistema | Grupo | Conteúdo | Granularidade | Competências |
|---|---|---|---|---|
| **SIHSUS** | `RD` | AIH — internações pagas pelo SUS | 1 linha = 1 internação | 2024-06 a 2026-05 |
| **CNES** | `LT` / `ST` | leitos e estabelecimentos | snapshot da rede | 2026-07 |
| **SIM** | `DO` | declarações de óbito | 1 linha = 1 óbito | 2021 a 2024 |
| **SINASC** | `DN` | declarações de nascido vivo | 1 linha = 1 nascimento | 2020 a 2022 |
| **IBGE** | — | população, Censo 2022, PIB | município | pendente |

O par `MUNIC_RES` (onde o paciente mora) × `MUNIC_MOV` (onde se internou) revela o **fluxo intermunicipal** — quais municípios exportam pacientes por falta de leito local. **30,01% das internações** de SP ocorrem fora do município de residência. É o insumo central do IPA.

Inventário completo em [docs/catalogo-bases.md](docs/catalogo-bases.md).

---

## Estrutura do repositório

```
scripts/                ingestão, upload, geração de DDL e execução de SQL
sql/00_setup/           usuários das camadas e credencial DBMS_CLOUD
sql/01_bronze/          external tables sobre os Parquet
sql/02_silver/          tratamento, domínios e dimensões
sql/03_gold/            tabela do painel e rotina de carga
docs/                   documentação técnica
notebooks/              exploração e validação
data/{raw,processed}    dados — fora do git
.claude/                contexto do projeto, skills e agents de OCI
```

### Scripts

| Script | O que faz |
|---|---|
| `download_files.py` | baixa DBC do FTP do DATASUS e converte para Parquet |
| `catalogo.py` | inventaria os Parquet → `docs/catalogo-bases.md` |
| `upload_oci.sh` | cria o bucket e sobe os Parquet; `--check` compara local × bucket |
| `gen_external_tables.py` | gera o DDL da Bronze a partir do schema real dos Parquet |
| `materializar_bronze.py` | carrega as tabelas físicas com `COPY_DATA` e retentativa |
| `criar_credencial.py` | cria a credencial `DBMS_CLOUD` sem expor a chave |
| `db.py` | executa SQL no ADB via wallet, mascarando segredos |
| `gen_dicionario.py` | gera o dicionário de dados a partir do banco |

---

## Como reproduzir

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

Conectar o Power BI: [docs/powerbi.md](docs/powerbi.md) → `GOLD.VW_PAINEL_ASSISTENCIAL`.

---

## Estado

| Etapa | Situação |
|---|---|
| Definição das bases | pronto |
| Download e conversão | 33 arquivos · 9.045.693 registros · 417 MB |
| Object Storage | 35 objetos no bucket `datasus-raw` |
| Autonomous Database | provisionado — Oracle 19c DW, Always Free |
| Bronze | 5 tabelas · 9.045.693 linhas |
| Silver | 6 tabelas + 6 domínios · sem perda de linhas |
| Gold | `gld_painel_assistencial` · 14.789 linhas |
| Power BI | conectável em `GOLD.VW_PAINEL_ASSISTENCIAL` |
| Vulnerabilidade social (IBGE) | pendente |
| Região de saúde no IPA | **bloqueado** |

### O bloqueio aberto

Todo o painel agrega por **região de saúde**, e nenhuma base baixada traz esse agrupamento de forma usável. O SIH só tem código IBGE de município, e o `REGSAUDE` do CNES é texto livre: **56% em branco**, 291 valores distintos, e o município de São Paulo sozinho aparece com `''`, `'0000'`, `'001'`, `'01'`, `'010'`. Apenas **58 dos 645 municípios** têm valor consistente.

Precisa vir da tabela oficial do DATASUS (Modalidade *Documentação* na Transferência de Arquivos). Sem ela não existe `VW_IPA_REGIAO` — e com ela caem o mapa, o ranking de regiões críticas e as perguntas do Select AI.

Este e os demais achados estão em [docs/problemas-conhecidos.md](docs/problemas-conhecidos.md).

---

## Equipe

**Grupo GreatMinds · 1TSCOA 2026**

| Integrante | Frente |
|---|---|
| Ana Karen da Silva Costa | Product Owner · Select AI · pitch e documentação |
| Gabriel Arcanjo dos Santos | Ingestão de dados |
| Guilherme Ruivo Talamonti | Ingestão de dados |
| Nathan de Oliveira Silva | Modelagem, IPA e APEX |
| Ryan Coutinho Oliveira | Modelagem, IPA e APEX |

---

*Challenge Oracle × FIAP 2026 · Dados públicos do DATASUS*
