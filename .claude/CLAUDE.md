# SUS Radar 360

Painel inteligente de monitoramento de **acesso hospitalar, vulnerabilidade social e risco epidemiológico**, sobre dados públicos do DATASUS. Challenge Oracle × FIAP 2026, grupo **GreatMinds** (turma 1TSCOA, Data Science). Entrega final em out/2026. MVP restrito a **São Paulo (UF = SP)**, agregado por **região de saúde**.

*"Um radar. Um sistema. Um giro completo."* — **Radar** = vigilância contínua e antecipação · **SUS** = ancoragem nos dados públicos · **360** = demanda, capacidade, vulnerabilidade e epidemiologia num mesmo painel.

---

## 1. O problema que o projeto resolve

O SUS gera grandes volumes de dados públicos — internações, hospitais, população, doenças, nascimentos, óbitos — espalhados em bases diferentes e difíceis de interpretar por gestores não técnicos. Decisões sobre leitos, equipes, campanhas e investimentos ainda dependem de análise manual e cruzamentos complexos. A pressão sobre o sistema não vem só do volume de internações: vem também de crescimento populacional, envelhecimento, baixa renda, falta de saneamento, alta de doenças e baixa oferta hospitalar.

> **Pergunta central:** quais municípios ou regiões apresentam maior risco de sobrecarga no sistema de saúde, considerando internações, estrutura hospitalar, perfil social, riscos epidemiológicos, natalidade e mortalidade?

**Público-alvo:** secretarias municipais e estaduais de saúde · gestores hospitalares · áreas de planejamento em saúde pública · equipes de vigilância epidemiológica.

**Critérios de aceite comprometidos com a banca** (cada benefício tem uma métrica):

| Benefício | Métrica |
|---|---|
| Identificar regiões com maior risco de sobrecarga | 100% das regiões de SP classificadas em verde, amarelo ou vermelho |
| Antecipar gargalos na rede hospitalar | alerta vermelho gerado ≥ 30 dias antes da ocupação crítica |
| Apoiar decisões sobre leitos, equipes e investimentos | 100% das recomendações estratégicas com lastro em IPA |
| Priorizar campanhas preventivas por território | top 10 territórios críticos publicados mensalmente |
| Reduzir dependência de consultas SQL manuais | 80% das perguntas resolvidas sem fila no time técnico |
| Transformar dados públicos em ações de gestão | tempo de resposta < 15s em 90% das perguntas frequentes |

---

## 2. Arquitetura

```
FONTES                 INGESTÃO              AUTONOMOUS DB           CONSUMO
SIH/SUS  ─┐                                  Staging                 APEX (dashboards)
CNES     ─┤─→  OCI Object Storage  ─→ External Tables → Bronze  ─→   Select AI (NL → SQL)
SIM/SINASC┤     /datasus/raw                          Silver         Power BI (camada BI)
IBGE     ─┘     /datasus/staging                      Gold
                /cnes/json          Oracle Data       Marts
                /socio/csv          Integration
```

Microdados DATASUS (DBC) → **OCI Object Storage** → **External Tables** no **Oracle Autonomous Database** → modelo **medallion** (Staging → Bronze → Silver → Gold → Marts) via **Oracle Data Integration + PL/SQL** → consumo em **APEX**, **Select AI** e **Power BI**.

| Tecnologia | Papel |
|---|---|
| DATASUS / TABNET | fontes públicas oficiais do Ministério da Saúde |
| Oracle Object Storage | armazenamento bruto e camadas de processamento |
| Oracle External Tables | leitura direta dos arquivos pelo banco, sem ETL pesado |
| Oracle Autonomous Database | camadas Staging, Bronze, Silver, Gold e Marts |
| Oracle Data Integration | movimentação entre camadas com pipelines SQL versionados |
| PL/SQL | tratamento, regras de negócio e cálculo de KPIs no banco |
| Oracle Select AI | perguntas em linguagem natural sobre os dados tratados |
| Oracle Analytics / Power BI | camada de BI e dashboards analíticos |

**Buckets:** `/datasus/raw` · `/datasus/staging` · `/cnes/json` · `/socio/csv`

---

## 3. Os cinco KPIs

| # | KPI | O que mede | De onde vem |
|---|---|---|---|
| 1 | **Demanda Hospitalar** | volume, crescimento e sazonalidade das internações por município, região, hospital, especialidade e tipo de atendimento | SIHSUS `RD` |
| 2 | **Capacidade Assistencial** | internações cruzadas com leitos, equipes e estrutura hospitalar | CNES `LT`, `ST`, `PF`/`EP` |
| 3 | **Vulnerabilidade Social** | população, renda, escolaridade, saneamento e PIB | IBGE (Censo 2022, SIDRA) |
| 4 | **Risco Epidemiológico e Vital** | doenças, agravos, natalidade e mortalidade | SIM, SINASC, SINAN |
| 5 | **IPA — Índice de Pressão do SUS** | índice consolidado que combina os quatro anteriores e ranqueia regiões críticas | derivado, PL/SQL na camada Gold/Marts |

O IPA é a entrega intelectual do projeto — não existe arquivo de origem, é cálculo próprio.

---

## 4. Contratos definidos pelo protótipo

As telas já foram desenhadas na Sprint 1, então o modelo tem alvo fixo.

**Dashboard principal** (SP · últimos 12 meses): KPIs de topo *Internações 12 meses*, *Média diária*, *Óbitos no período*; gráfico *Internações mensais por região*; painel *Risco geral*; lista **TOP 5 EM ALERTA** por região de saúde com nota de IPA.

**View exposta ao Select AI** — o SQL que o protótipo mostra como gerado:

```sql
SELECT regiao_saude, ipa, semaforo FROM VW_IPA_REGIAO
WHERE semaforo = 'VERMELHO' ORDER BY ipa DESC;
```

Contrato mínimo: `VW_IPA_REGIAO (regiao_saude, ipa, semaforo)`, com `semaforo ∈ {VERDE, AMARELO, VERMELHO}` e `ipa` numérico de 0 a 100.

**A view existe e responde** — 62 de 62 regiões classificadas (29 verdes, 32 amarelas, 1 vermelha), sobre a janela móvel dos últimos 12 meses carregados. Junto dela, mais 6 views por região em `sql/03_gold/03_gld_regiao.sql`, com camada semântica de 116 comentários em `sql/04_select_ai/01_camada_semantica.sql`. O perfil `SUSRADAR` está criado, mas **o Select AI ainda não responde**: a tenancy tem cota zero no OCI Generative AI (serviço pago, fora do Always Free). Diagnóstico e as duas saídas em `docs/select-ai.md`.

**Perguntas que o gestor precisa conseguir fazer** — casos de teste do modelo semântico:

1. Quais regiões de SP estão em alerta vermelho neste mês?
2. Quais municípios tiveram maior aumento de internações no último trimestre?
3. Quais hospitais têm permanência média acima da média estadual?
4. Compare internações e leitos disponíveis por região de saúde.
5. Onde a pressão por internações respiratórias está crescendo mais rápido?
6. Quais regiões pioraram entre o último semestre e o atual?

> Os números das telas do protótipo (IPA 94 para São José do Rio Preto, 27,62 mi de internações etc.) são **mock**, não resultado calculado. Nunca citar como achado.

---

## 5. As bases de dados

Fonte primária: **Transferência de Arquivos do DATASUS** (microdados DBC). TABNET serve só para validar totais. Socioeconômico vem do IBGE.

| Sistema | Grupo | Arquivo (SP) | Granularidade | Periodicidade |
|---|---|---|---|---|
| **SIHSUS** | `RD` (AIH Reduzida) | `RDSP<AAMM>.dbc` | 1 linha = 1 internação | mensal |
| **CNES** | `LT` (leitos), `ST` (estabelecimentos) | `LTSP<AAMM>.dbc`, `STSP<AAMM>.dbc` | snapshot da rede | mensal |
| **SIM** | `DO` | `DOSP<AAAA>.dbc` | 1 linha = 1 óbito | anual |
| **SINASC** | `DN` | `DNSP<AAAA>.dbc` | 1 linha = 1 nascido vivo | anual |
| **SINAN** | por agravo | nacional | 1 linha = 1 notificação | — |
| **IBGE** | pop., Censo 2022, PIB | CSV/SIDRA | município | — |

### O que cada base significa

- **SIHSUS RD** — AIH (Autorização de Internação Hospitalar) é o documento pelo qual o hospital é pago pelo SUS. O par `MUNIC_RES` (onde o paciente mora) ≠ `MUNIC_MOV` (onde se internou) revela o **fluxo intermunicipal** de pacientes — quais regiões exportam gente por falta de leito local. É o insumo central do IPA.
- **CNES LT/ST** — inventário, não evento: quantos leitos existem (`QT_EXIST`) e quantos são SUS (`QT_SUS`), por hospital. É o **denominador** do painel; cruza com o SIH pelo campo `CNES`.
- **SIM DO** — Declaração de Óbito de toda a população, não só de quem internou (por isso difere do campo `MORTE` do SIH). Causa básica em CID-10.
- **SINASC DN** — Declaração de Nascido Vivo: peso, gestação, pré-natal, Apgar, idade da mãe. Proxy de qualidade da atenção básica e denominador materno-infantil.

### Colunas-chave

- **SIH RD:** `MUNIC_RES`, `MUNIC_MOV`, `CNES`, `N_AIH`, `DT_INTER`, `DT_SAIDA`, `DIAS_PERM`, `DIAG_PRINC` (CID-10), `PROC_REA`, `ESPEC`, `CAR_INT`, `COMPLEX`, `MORTE`, `IDADE`/`COD_IDADE`, `SEXO`, `UTI_MES_TO`, `VAL_TOT`
- **CNES LT:** `CNES`, `CODUFMUN`, `TP_LEITO`, `CODLEITO`, `QT_EXIST`, `QT_SUS`, `QT_CONTR`, `COMPETEN`
- **CNES ST:** `CNES`, `CODUFMUN`, `TP_UNID`, `TPGESTAO`, `VINC_SUS`, `NAT_JUR`, `NIV_HIER`
- **SIM DO:** `CODMUNRES`, `DTOBITO`, `CAUSABAS` (CID-10), `IDADE`, `SEXO`, `LOCOCOR`
- **SINASC DN:** `CODMUNRES`, `CODMUNNASC`, `DTNASC`, `PESO`, `GESTACAO`, `CONSPRENAT`, `APGAR5`, `IDADEMAE`
- **SINAN:** `ID_AGRAVO`, `DT_NOTIFIC`, `SG_UF`/`ID_MN_RESI`, `DT_SIN_PRI`

### Ordens de grandeza (SP)

SIH RD ≈ 240–250 mil internações/mês, 113 colunas, ~19 MB DBC → ~11 MB Parquet. Num mês típico: ~620 hospitais, ~1.370 municípios de residência, permanência média ~5 dias, mortalidade hospitalar ~4,8%.

### Tabelas auxiliares

Baixar pela Modalidade *Documentação* / *Arquivos auxiliares* de cada Fonte: CID-10, procedimentos SIGTAP, de/para municípios ↔ regiões de saúde de SP, tipos de leito/estabelecimento/natureza jurídica, e os dicionários de variáveis de cada sistema.

> **Região de saúde — resolvido.** Todo o painel agrega por região de saúde e nenhum **microdado** traz esse agrupamento (o SIH só tem código IBGE de município). O de/para está em outra árvore do FTP: a **Base Territorial** em `ftp.datasus.gov.br/territorio/tabelas/<AAAA>/`, não em `/dissemin/publicos/`. Carregada por `scripts/territorio.py` — 645/645 municípios de SP em 62 regiões, 0 internações sem região. Traz também nome e coordenada do município, que o SIH não tem.

---

## 6. Ingestão — `download_files.py`

Baixa via FTP oficial o conjunto SP, converte **DBC → DBF → Parquet** e gera manifesto. Não usa `pysus` (evita quebras de API). Arquivo ausente não interrompe a execução.

```bash
.venv/bin/python scripts/download_files.py --uf SP --cnes-mes 202607 \
    --sim-anos 2021 2022 2023 2024 --sinasc-anos 2020 2021 2022
.venv/bin/python scripts/catalogo.py     # inventário -> docs/catalogo-bases.md
```

Documentação completa da ingestão, com o passo de conferir o FTP antes de escolher
competências: `docs/ingestao.md`.

Saídas:

```
data/raw/<sistema>/*.dbc          # bruto, como veio do DATASUS
data/processed/<sistema>/*.parquet
data/manifesto.csv                # arquivo, sistema, linhas, colunas, status
```

Caminhos FTP (`ftp.datasus.gov.br`):

- SIH RD: `/dissemin/publicos/SIHSUS/200801_/Dados/RD{UF}{AAMM}.dbc`
- CNES LT/ST: `/dissemin/publicos/CNES/200508_/Dados/{LT|ST}/{LT|ST}{UF}{AAMM}.dbc`
- SIM DO: `/dissemin/publicos/SIM/CID10/DORES/DO{UF}{AAAA}.dbc`
- SINASC DN: `/dissemin/publicos/SINASC/NOV/DNRES/DN{UF}{AAAA}.dbc`

### Cuidados ao rodar

- **Os defaults do script envelhecem.** Ele calcula as competências a partir da data de hoje e não verifica se existem. Sempre listar o FTP antes e passar as competências na mão. Os sistemas têm defasagens diferentes: SIH publica com ~2–3 meses de atraso, CNES é quase corrente, SIM e SINASC atrasam 1–2 anos e o SINASC costuma ficar mais atrás que o SIM.
- Competências recentes podem ser preliminares; o script pula ausentes e registra `nao encontrado` no manifesto.
- `data/manifesto.csv` só é escrito no fim da execução.
- Encoding dos DBF é `latin-1`.
- Um mês de SIH leva alguns minutos para converter — a carga completa é longa, rodar em background.
- **Todos os códigos vêm crus** (município IBGE, CID-10, SIGTAP, tipo de leito). Traduzir é trabalho da camada Silver e depende das tabelas auxiliares.

### Defeitos conhecidos dos arquivos do DATASUS

- **DBF sem terminador de cabeçalho.** Visto no CNES `ST`: o byte que fecha a lista de campos vem `0x00` em vez de `0x0D`, e o `dbfread` estoura com `unpack requires a buffer of 32 bytes`. Corrigido automaticamente por `reparar_dbf()` no script.
- **`DT_INTER` nao e a competencia.** A AIH e faturada por competencia, mas `DT_INTER` guarda a data real de admissao — 2,66% das linhas tem admissao anterior a janela carregada, chegando a 2008 (cronicos, permanencia media de 30 dias). Serie mensal do painel usa `ano/mes_competencia`; usar `dt_internacao` cria cauda falsa de 217 meses.
- **`COPY_DATA` nao tolera schema drift** (a External Table tolera). Os 9 arquivos de SIH com 113 colunas falham com `ORA-00947` contra a tabela de 114 — carregar via staging de 113 colunas e mover com `INSERT ... SELECT`, deixando `FONTE_ORC` nula.
- **`REGSAUDE` do CNES e inutilizavel:** 56% em branco, 291 valores distintos, so 58 dos 645 municipios com valor consistente. O de/para municipio -> regiao de saude tem que vir da tabela oficial do DATASUS.
- **Schema do SIH muda em 2025-03:** 113 colunas até 2025-02, 114 a partir daí (acrescentou `FONTE_ORC`). External Table com `'schema' VALUE 'first'` perde a coluna em silêncio — declare `column_list` explícito. Detalhes e alternativas em `docs/ingestao.md`.

---

## 7. Convenções do repositório

```
data/{raw,processed}         # dados — no .gitignore, nunca versionar
scripts/                     # download_files.py (ingestão) · territorio.py (região de saúde) · catalogo.py
sql/{00_setup,01_bronze,02_silver,03_gold,04_select_ai}
docs/                        # ingestao.md · select-ai.md · catalogo-bases.md (gerado)
notebooks/                   # 01_panorama_bases · 02_sih_demanda · 03_regiao_saude
.claude/{skills,agents}/     # skills de OCI e o agent oci-engineer
```

- **Microdados não vão pro git.** `data/`, `*.dbc` e `*.dbf` estão no `.gitignore`.
- Ambiente Python em `.venv/` (3.10): `datasus-dbc`, `dbfread`, `pandas`, `pyarrow`, `python-pptx`. Usar `.venv/bin/python`, não o Python do sistema.
- Documentação e comentários em **português**.
- Sempre registrar a competência baixada nos metadados — o painel precisa saber a que mês cada número se refere.

### Restrições de ambiente

O repositório fica no **WSL** e o download precisa rodar **localmente**: sessões em nuvem rejeitam caminhos UNC (`\\wsl.localhost\...`) e bloqueiam por política de egress os domínios do DATASUS. Ingestão é sempre execução local.

---

## 8. Decisões técnicas e suas razões

O deck da Sprint 1 desenhou a ingestão de um jeito; a implementação divergiu conscientemente. Cada divergência precisa aparecer na documentação técnica.

| Item | Planejado no deck | Adotado | Razão |
|---|---|---|---|
| Fonte | TABNET (CSV/XLSX agregado) | Transferência de Arquivos (microdado DBC) | agregado não permite calcular fluxo intermunicipal nem permanência média por hospital — duas das perguntas prometidas ao Select AI |
| Conversão | DBC → CSV via `pyreaddbc` | DBC → Parquet via `datasus-dbc` + `dbfread` | Parquet preserva tipos, comprime ~3× e é lido por External Table; `pyreaddbc` está desatualizado |
| CNES | API CNES (JSON) → `/cnes/json` | FTP DBC (`LTSP`/`STSP`) | microdado completo e histórico; a API é por estabelecimento e não serve a carga em massa |
| SINAN | previsto nas cinco frentes | fora do conjunto padrão | arquivos nacionais por agravo; entra depois, com foco em dengue e respiratórios |
| Ingestão | — | carga **manual e única** | escopo do MVP; não há pipeline contínuo |

---

## 9. Time e sprints

| Integrante | RM | Frente |
|---|---|---|
| Ana Karen da Silva Costa | 572391 | Product Owner (S1–S6) · Select AI (S4–S5) · pitch, README e PPT (S5) |
| Gabriel Arcanjo dos Santos | 566969 | Ingestão de dados (S2) |
| Guilherme Ruivo Talamonti | 573396 | Ingestão de dados (S2) |
| Nathan de Oliveira Silva | 570059 | Modelagem, IPA e APEX (S3–S4) |
| Ryan Coutinho Oliveira | 570573 | Modelagem, IPA e APEX (S3–S4) |

**Sprints:** S1 Ideação e Arquitetura (16/JUN) · S2 Ingestão (30/JUN) · S3 Modelo IPA (21/JUL) · S4 MVP + Select AI (18/AGO) · S5 Pitch e Documentação (08/SET) · S6 Buffer e Entrega Final (06/OUT).

**Escopo da Sprint 2 (ingestão):** download DBC do SIH/SUS de SP · conversão · upload no OCI Object Storage · dados de CNES e IBGE · External Tables apontando para os arquivos · documentação técnica no GitHub.

**Escopo da Sprint 3 (modelagem):** camadas Staging → Bronze → Silver · Gold e Marts com agregações regionais · PL/SQL do cálculo do IPA · validação estatística com o tutor.

**Cerimônias:** Scrum + Kanban. Daily de 15 min no Discord (seg–sex, 21h) · Planning quinzenal · Review e Retro com o tutor ao fim de cada marco · Kanban no Notion (Backlog → Doing → Review → Done).

---

## 10. Referências

- Transferência de Arquivos: https://datasus.saude.gov.br/transferencia-de-arquivos/
- TABNET: https://datasus.saude.gov.br/informacoes-de-saude-tabnet/
- FTP de microdados: `ftp://ftp.datasus.gov.br/dissemin/publicos/`
- `datasus-dbc`: https://pypi.org/project/datasus-dbc/ · `dbfread`: https://dbfread.readthedocs.io/
- PySUS (alternativa): https://github.com/AlertaDengue/PySUS
- IBGE (população, Censo 2022, PIB): https://sidra.ibge.gov.br/
- Dicionários de variáveis: Modalidade *Documentação* de cada Fonte na página de transferência
- Deck da Sprint 1: `.claude/context/Sprint_1_Template_IDEACAO_ARQUITETURA_Challenge_2026_01_v1.pptx`

---

*Grupo GreatMinds · 1TSCOA 2026 · Challenge Oracle × FIAP*
