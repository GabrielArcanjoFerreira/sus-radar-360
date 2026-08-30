# Ingestão de dados — Sprint 2

Carga **manual e única** dos microdados do DATASUS para São Paulo. Não há pipeline contínuo: o conjunto é baixado, convertido e publicado uma vez, e o restante do projeto trabalha sobre ele.

Responsáveis: Gabriel Arcanjo e Guilherme Talamonti.

## Fluxo

```
FTP DATASUS ──► data/raw/*.dbc ──► data/processed/*.parquet ──► OCI Object Storage ──► External Tables (Bronze)
             download            decompress + DBF→Parquet      bulk-upload            DBMS_CLOUD
```

## Como reproduzir

```bash
python3 -m venv .venv
.venv/bin/pip install datasus-dbc dbfread pandas pyarrow

# 1. conferir o que existe no FTP antes de escolher as competências
.venv/bin/python - <<'EOF'
import ftplib, socket
socket.setdefaulttimeout(60)
f = ftplib.FTP('ftp.datasus.gov.br'); f.login(); f.set_pasv(True)
for path, pref in [('/dissemin/publicos/SIHSUS/200801_/Dados', 'RDSP'),
                   ('/dissemin/publicos/CNES/200508_/Dados/LT', 'LTSP'),
                   ('/dissemin/publicos/CNES/200508_/Dados/ST', 'STSP'),
                   ('/dissemin/publicos/SIM/CID10/DORES', 'DOSP'),
                   ('/dissemin/publicos/SINASC/NOV/DNRES', 'DNSP')]:
    n = sorted(x.rsplit('/',1)[-1] for x in f.nlst(path) if x.rsplit('/',1)[-1].startswith(pref))
    print(f'{pref}: {len(n)} arquivos, últimos {n[-3:]}')
EOF

# 2. baixar (longo — rodar em background)
.venv/bin/python scripts/download_files.py --uf SP --cnes-mes 202607 \
    --sim-anos 2021 2022 2023 2024 --sinasc-anos 2020 2021 2022

# 3. inventariar
.venv/bin/python scripts/catalogo.py
```

**Não confie nos defaults do script.** Ele deriva as competências da data de hoje e não verifica se o arquivo existe. Cada sistema tem defasagem própria: SIH publica com ~2–3 meses de atraso, CNES é quase corrente, SIM e SINASC atrasam 1–2 anos, e o SINASC costuma ficar mais atrás que o SIM. Sempre liste o FTP antes (passo 1).

## Conjunto carregado

Ver [catalogo-bases.md](catalogo-bases.md) para o inventário completo. Em resumo: **33 arquivos, 9.045.693 registros, 417 MB em Parquet**.

| Sistema | Competências | Critério |
|---|---|---|
| SIHSUS RD | 2024-06 a 2026-05 (24 meses) | janela de 24 meses com ~3 meses de defasagem de consolidação; o painel promete "últimos 12 meses" e séries comparativas semestre a semestre, o que exige 24 |
| CNES LT/ST | 2026-07 | snapshot mais recente disponível; capacidade é foto, não série |
| SIM DO | 2021 a 2024 | tudo que o DATASUS publicou até hoje |
| SINASC DN | 2020 a 2022 | 2023 ainda não publicado |
| SINAN | — | fora do escopo desta carga; arquivos nacionais por agravo, entra depois com foco em dengue e respiratórios |

## Decisões técnicas

**Microdado, não TABNET.** O deck da Sprint 1 previa CSV agregado do TABNET. Agregado não permite calcular fluxo intermunicipal (`MUNIC_RES` ≠ `MUNIC_MOV`) nem permanência média por hospital — duas das perguntas prometidas ao Select AI. A fonte passou a ser a Transferência de Arquivos.

**Parquet, não CSV.** O deck previa `pyreaddbc` gerando CSV. Parquet preserva tipos, comprime ~40% contra o DBC (417 MB contra 660 MB) e é lido nativamente por External Table. `pyreaddbc` está desatualizado; usamos `datasus-dbc` + `dbfread`.

**CNES por FTP, não por API.** O deck previa a API do CNES devolvendo JSON. A API é por estabelecimento e não serve a carga em massa; o FTP entrega o cadastro completo do estado em um arquivo.

**Sem `pysus`.** A biblioteca muda de API com frequência. FTP puro (`ftplib`) mais `datasus-dbc` tem menos superfície de quebra.

## Problemas encontrados

### DBF do CNES ST sem terminador de cabeçalho

`STSP2607.dbc` descomprimia normalmente mas falhava na leitura com `unpack requires a buffer of 32 bytes`.

O arquivo estava íntegro — `header_len (6689) + registros (115.148) × record_len (499)` bate byte a byte com o tamanho. O defeito é que o DATASUS gravou `0x00` no offset 6688, onde o padrão DBF exige `0x0D` para fechar a lista de descritores de campo. O `dbfread` lê blocos de 32 bytes procurando esse terminador; sem ele, varreu os 57 MB de dados como se fossem definições de campo e estourou no fim.

Corrigido em `scripts/download_files.py` pela função `reparar_dbf()`, que roda após cada descompressão: lê o `header_len` dos bytes 8–9, confere o byte terminador e grava `0x0D` se estiver ausente. É defeito de geração do DATASUS, não desta competência — outras competências de CNES ST devem apresentar o mesmo.

### Schema do SIH muda em 2025-03

O SIH RD tem **113 colunas até 2025-02 e 114 a partir de 2025-03**: foi acrescentada `FONTE_ORC` (fonte do recurso orçamentário, `CHAR(2)`, sem nulos, valor `'00'` em 100% das linhas de março/2025).

Isso importa diretamente para a camada Bronze. `DBMS_CLOUD.CREATE_EXTERNAL_TABLE` com `'schema' VALUE 'first'` lê o layout do **primeiro** arquivo do `file_uri_list` e aplica a todos os demais. Se a lista começar por uma competência de 2024, `FONTE_ORC` some silenciosamente de 2025-03 em diante; se começar por 2025-03, as competências antigas podem falhar ou preencher lixo.

Três saídas, em ordem de preferência:

1. **Declarar `column_list` explicitamente** com as 114 colunas, em vez de inferir. A `FONTE_ORC` fica nula nas competências antigas, que é a semântica correta.
2. Duas External Tables (`BRZ_SIH_RD_ATE_202502` e `BRZ_SIH_RD_DE_202503`) unificadas por view na Silver.
3. Descartar `FONTE_ORC` se o IPA não a usar — mas isso precisa ser decisão consciente, registrada.

**Antes de criar qualquer External Table, rode a última célula do notebook [01_panorama_bases](../notebooks/01_panorama_bases.ipynb)**, que detecta divergência de layout entre competências de todos os sistemas.

## Validação

O que foi conferido:

- `data/manifesto.csv` — 33 de 33 arquivos com status `ok`
- Cobertura temporal do SIH sem buracos: 24 meses contínuos de 2024-06 a 2026-05
- CNES ST cobre **645 municípios**, exatamente o total de São Paulo
- Ordem de grandeza do SIH coerente: 225–259 mil internações/mês, ~620 hospitais, permanência média ~5 dias, letalidade ~4,8%
- Colunas-chave de cada base presentes e com os nomes esperados

O que **ainda não** foi conferido e precisa ser antes da modelagem:

- Totais contra o TABNET (validação externa dos números)
- Consistência de domínio dos códigos (CID-10 válido, SIGTAP existente, município IBGE existente)

## Pendências da Sprint 2

1. **Tabelas auxiliares** — CID-10, SIGTAP, tipos de leito/estabelecimento/natureza jurídica, e sobretudo o **de/para município → região de saúde de SP**. O CNES traz `REGSAUDE` no cadastro de estabelecimentos, e o notebook [03_regiao_saude](../notebooks/03_regiao_saude.ipynb) testa se dá para derivar o mapeamento daí. Se a perda de cobertura for relevante, é obrigatório baixar a tabela oficial: `VW_IPA_REGIAO` depende dela.
2. **IBGE** — população, Censo 2022 e PIB municipal (SIDRA) para o KPI 3.
3. **Upload no OCI Object Storage** — ver skill `oci-object-storage`.
4. **External Tables** no Autonomous Database — ver skill `oci-external-tables`, atentando ao schema drift acima.
