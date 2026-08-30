# Problemas conhecidos

Defeitos dos dados e armadilhas de ferramenta encontrados na construção. Todos verificados nos dados reais, não supostos.

## Bloqueia a Gold

### Região de saúde não existe em nenhuma base baixada

Todo o painel agrega por **região de saúde**, e nenhuma base traz esse agrupamento de forma usável:

- O SIH só tem código IBGE de município.
- O `REGSAUDE` do CNES é texto livre: **56% em branco**, 291 valores distintos, e o município de São Paulo (355030) sozinho aparece com `''`, `'0000'`, `'001'`, `'01'`, `'010'`, `'0100'`, `'013'`. Só **58 dos 645 municípios** têm valor consistente.

`slv_municipio.regiao_saude` está nula nos 3.473 municípios. Sem a tabela oficial do DATASUS (Modalidade *Documentação* na Transferência de Arquivos), **`VW_IPA_REGIAO` não existe** — e com ela caem o mapa, o "Top 5 em alerta" e as perguntas do Select AI sobre regiões.

É o único bloqueio duro do projeto.

## Defeitos dos arquivos do DATASUS

### DBF do CNES ST sem terminador de cabeçalho

`STSP2607.dbc` descomprimia normalmente mas estourava na leitura com `unpack requires a buffer of 32 bytes`.

O arquivo estava íntegro — `header_len (6689) + 115.148 × record_len (499)` bate byte a byte com o tamanho. O DATASUS gravou `0x00` no offset 6688, onde o padrão DBF exige `0x0D` para fechar a lista de descritores de campo. O `dbfread` varreu os 57 MB de dados procurando o terminador e estourou no fim.

Corrigido por `reparar_dbf()` em `scripts/download_files.py`, que roda após cada descompressão. É defeito de geração, não desta competência — outras competências de CNES ST devem apresentar o mesmo.

### Schema do SIH muda em 2025-03

113 colunas até 2025-02, 114 a partir de 2025-03. A coluna nova é `FONTE_ORC` (fonte do recurso orçamentário, `CHAR(2)`, `'00'` em 100% das linhas).

Duas consequências distintas:

**External Table.** Com `'schema' VALUE 'first'`, o Oracle lê o layout do primeiro arquivo do `file_uri_list` e aplica aos demais — a coluna sumiria em silêncio das 15 competências que a têm. Por isso `scripts/gen_external_tables.py` declara `column_list` explícito com a **união** das colunas de todas as competências.

**`COPY_DATA`.** Ao contrário da External Table, não tolera divergência: falhou em exatamente os 9 arquivos de 113 colunas com `ORA-00947: not enough values`. A carga desses arquivos passa por uma staging de 113 colunas e um `INSERT ... SELECT` que deixa `FONTE_ORC` nula.

### `DT_INTER` não é a competência

A AIH é faturada por competência, mas `DT_INTER` guarda a data real de admissão. **2,66% das internações (155.680)** têm admissão anterior à janela carregada, chegando a **2008** — são crônicos e clínica médica, com permanência média de 16 dias contra 5 dos demais.

`MIN(dt_internacao)` na Silver devolve 2008 e 217 competências distintas, para uma carga de 24 meses.

Séries mensais do painel usam `ano_competencia` e `mes_competencia`. Agrupar por `dt_internacao` cria uma cauda falsa de 17 anos.

## Ressalvas de medida

### 2,6% dos IPAs são impossíveis

384 de 14.658 linhas dão IPA acima de 100%, o que não existe para taxa de ocupação. São 86 estabelecimentos com permanência média de 13,3 dias contra 5,2 dos demais — hospitais de longa permanência (tipos CNES 05 e 07). O extremo é um estabelecimento com 3 leitos cadastrados e 1.421 dias de permanência, dando 1.578%.

Duas causas, ambas do denominador:

1. O CNES é **snapshot único de 2026-07** aplicado a 24 meses de SIH. Leito fechado ou recadastrado depois não aparece na competência certa.
2. O IPA divide **todas** as internações por **todos** os leitos, sem casar especialidade.

Tratamento, por esforço crescente: filtrar `ipa_percentual <= 100` nos rankings; baixar o CNES LT por competência; casar `TP_LEITO` do CNES com `ESPEC` da AIH.

Sem o filtro, o "Top 10 CNES por IPA" mostra exatamente esses artefatos no topo.

### Limiares de risco são inferidos

A base de referência só contém `ESTÁVEL` (até 41,25) e `MÉDIO RISCO` (60,67 a 66,74). O ponto de corte entre elas e os limites de `CRÍTICO` e `COLAPSO` **não são observáveis nos dados**. Adotadas as faixas clássicas de ocupação: 50 / 75 / 100.

Para mudar, altere só `gld_faixa_risco` — a rotina lê os limiares de lá.

## Divergências no dashboard atual

Conferido contra a base de referência com filtro `Estado = AM`:

| Card | Dashboard | Base | Situação |
|---|---|---|---|
| Internações | 43 | 43 | correto |
| Permanência Média | 5,49 | 5,49 | correto |
| Maior IPA | 286 | **2,86%** | a medida multiplica por 100 um valor que já é percentual |
| Nível de Risco | CRÍTICO / COLAPSO | 27 de 27 linhas são **ESTÁVEL** | o card não respeita o filtro |

## Armadilhas de ferramenta

### OCI CLI

- **`--namespace` é opção do subcomando**, não do grupo `os`. Em `oci os --namespace X bucket get` o CLI sai com código 2 (erro de uso).
- **A resolução implícita de namespace falha nesta tenancy**: `object list` devolve `BucketNotFound` sem `--namespace`, mesmo com o bucket existindo e `object put` funcionando. Passe sempre explícito.
- **`length(data)` estoura em bucket vazio** — o CLI devolve `data: null` e o JMESPath falha com `JMESPathTypeError` em vez de retornar 0.
- **`bulk-upload` imprime `Uploaded <arquivo>` mesmo quando o envio falha.** O resultado autoritativo é o mapa `upload-failures` do JSON de saída, não o texto de progresso nem o código de saída.
- **O bucket não fica visível no endpoint de objetos imediatamente** após a criação. `scripts/upload_oci.sh` espera até `object list` responder.

### Oracle

- **Autorização devolve 404, não 403.** Falta de policy IAM é indistinguível de recurso inexistente na mensagem.
- **`ORA-12801` e `ORA-29913` escondem a causa real.** Rode com `ALTER SESSION DISABLE PARALLEL QUERY` e leia a exceção completa, não a primeira linha.
- **Criar External Table não valida a URI** — só falha na primeira consulta. Sempre rode um `COUNT(*)` depois de criar.
- **`GRANT SELECT` precisa rodar depois das tabelas existirem.** O loop de `sql/00_setup/00_usuarios.sql` sobre `all_tables` não concede nada se a camada anterior ainda estiver vazia.
- **Nome não qualificado resolve no schema do usuário logado**, não no que o navegador do Database Actions exibe. Use `SILVER.SLV_INTERNACAO` ou `ALTER SESSION SET CURRENT_SCHEMA`.
- **`GROUP BY 1` não existe no Oracle.** Repita a expressão ou use uma CTE.

### Power BI

- A tela de credenciais abre na aba **Windows**, que falha mesmo com usuário e senha corretos. É preciso clicar em **Banco de Dados**.
- `ORA-12154` quase sempre é `TNS_ADMIN` ausente ou Power BI não reiniciado depois de defini-lo.
- `SetEnvironmentVariable` com escopo `"Machine"` exige PowerShell elevado; `"User"` não, e basta.

### Always Free

- **O ADB hiberna após 7 dias sem conexão e é reclamado após 90 dias inativo.** Entre a Sprint 3 e a entrega de outubro isso apaga o banco. Alguém precisa conectar semanalmente.
- Cota de 20 GiB no Object Storage; a carga atual usa 417 MB (2%).
