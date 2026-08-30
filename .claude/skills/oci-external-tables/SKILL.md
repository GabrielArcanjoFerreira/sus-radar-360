---
name: oci-external-tables
description: Cria a credencial DBMS_CLOUD e as External Tables do Autonomous Database sobre os Parquet do Object Storage, formando a camada Bronze. Use ao ligar o banco aos arquivos, criar/validar external table, diagnosticar ORA-20000/ORA-29913 ou conferir logs de carga.
---

# External Tables — ligando o banco aos arquivos

Fecha o caminho `Object Storage → Bronze`. Depois disso, a dupla de modelagem trabalha só em SQL.

## Pré-requisitos

- Buckets carregados (skill `oci-object-storage`)
- ADB disponível e usuário `bronze` criado com `GRANT EXECUTE ON DBMS_CLOUD` (skill `oci-autonomous-db`)
- Conectado como `bronze`, **não** como ADMIN

## 1. Credencial DBMS_CLOUD

O banco precisa de credencial própria para ler o bucket — a autenticação do CLI não vale dentro do ADB.

Opção A — chave API (recomendada, não expira):

```sql
BEGIN
  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'CRED_OCI',
    user_ocid       => 'ocid1.user.oc1..<...>',
    tenancy_ocid    => 'ocid1.tenancy.oc1..<...>',
    private_key     => '<conteúdo do .pem SEM as linhas BEGIN/END e sem quebras>',
    fingerprint     => 'xx:xx:...');
END;
/
```

Opção B — Auth Token (mais simples de gerar, mas é senha de usuário):

```sql
BEGIN
  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'CRED_OCI',
    username        => '<usuário da tenancy>',
    password        => '<auth token gerado no console>');
END;
/
```

**Este é o único ponto do projeto em que uma chave privada entra num comando.** Regras:
- Gere o SQL num arquivo temporário fora do repo (use o scratchpad), rode, e apague.
- Nunca escreva a credencial em `sql/` versionado — versione um template com placeholders.
- Nunca imprima o `.pem` no chat nem em log.

Validar:

```sql
SELECT credential_name, username, enabled FROM user_credentials;
```

## 2. Criar as External Tables

Parquet carrega o próprio schema, então não declare colunas — `DBMS_CLOUD` infere.

```sql
BEGIN
  DBMS_CLOUD.CREATE_EXTERNAL_TABLE(
    table_name      => 'BRZ_SIH_RD',
    credential_name => 'CRED_OCI',
    file_uri_list   => 'https://objectstorage.<região>.oraclecloud.com/n/<ns>/b/datasus-raw/o/processed/sihsus/*.parquet',
    format          => JSON_OBJECT('type' VALUE 'parquet', 'schema' VALUE 'first'));
END;
/
```

`'schema' VALUE 'first'` lê o schema do primeiro arquivo e aplica a todos — correto aqui, porque todos os meses de SIH têm as mesmas 113 colunas. **Se algum sistema mudar de layout entre competências, isso quebra em silêncio**: colunas novas somem e o tipo do primeiro arquivo vence. Valide a contagem de colunas por ano antes de agrupar num único `file_uri_list`.

Tabelas a criar:

| Tabela | Prefixo no bucket | Origem |
|---|---|---|
| `BRZ_SIH_RD` | `processed/sihsus/*.parquet` | internações (1 linha = 1 AIH) |
| `BRZ_CNES_LT` | `processed/cnes/LT*.parquet` | leitos |
| `BRZ_CNES_ST` | `processed/cnes/ST*.parquet` | estabelecimentos |
| `BRZ_SIM_DO` | `processed/sim/*.parquet` | óbitos |
| `BRZ_SINASC_DN` | `processed/sinasc/*.parquet` | nascidos vivos |

CNES `LT` e `ST` têm schemas diferentes — precisam de tabelas separadas, não use `processed/cnes/*.parquet`.

## 3. Validar

```sql
-- estrutura inferida
SELECT column_name, data_type, data_length FROM user_tab_columns
 WHERE table_name = 'BRZ_SIH_RD' ORDER BY column_id;

-- o dado chega?
SELECT COUNT(*) FROM BRZ_SIH_RD;
SELECT * FROM BRZ_SIH_RD FETCH FIRST 5 ROWS ONLY;
```

**Confira contra o `data/manifesto.csv` local.** A soma da coluna `linhas` do manifesto tem que bater com o `COUNT(*)`. Se não bater, um arquivo não subiu ou o wildcard não pegou tudo — investigue antes de seguir, porque todo o IPA herda esse erro.

Sanidade do domínio, não só do volume:

```sql
SELECT MIN(DT_INTER), MAX(DT_INTER), COUNT(DISTINCT MUNIC_RES), COUNT(DISTINCT CNES)
  FROM BRZ_SIH_RD;
```

Esperado para SP: ~1.370 municípios de residência e ~620 hospitais por mês; datas dentro das competências baixadas. Município fora da faixa `35xxxx` indica residente de outro estado internado em SP — é legítimo, não é erro.

## 4. Diagnóstico

Erros de carga não aparecem no `SELECT`; vão para tabelas de log.

```sql
SELECT * FROM user_load_operations ORDER BY start_time DESC FETCH FIRST 10 ROWS ONLY;
```

As colunas `logfile_table` e `badfile_table` apontam para tabelas com o detalhe.

| Sintoma | Causa provável |
|---|---|
| `ORA-20401: Authorization failed` | credencial errada, ou o usuário não tem policy de leitura no bucket |
| `ORA-29913` / `ORA-20000` na consulta | URI inválida, objeto inexistente, ou wildcard sem match |
| Tabela criada mas `COUNT(*) = 0` | prefixo do `file_uri_list` não corresponde ao caminho real — liste o bucket e compare |
| `ORA-00942` em `DBMS_CLOUD` | falta `GRANT EXECUTE ON DBMS_CLOUD` ao usuário |
| Colunas viraram tudo `VARCHAR2` | schema não inferido; o arquivo pode não ser Parquet válido |

A criação da External Table **não valida a URI** — ela só falha na primeira consulta. Sempre rode um `COUNT(*)` depois de criar.

## 5. Materializar (opcional)

External Table relê o Object Storage a cada consulta — bom para carga única, ruim para dashboard interativo. Se o APEX ficar lento, materialize:

```sql
CREATE TABLE BRZ_SIH_RD_MAT AS SELECT * FROM BRZ_SIH_RD;
```

Ou use `DBMS_CLOUD.COPY_DATA` para carregar direto numa tabela física, que dá controle de erro por linha. Decisão da dupla de modelagem — o Bronze pode ser externo, mas Silver e Gold devem ser físicos.

## Versionamento

Salve todo SQL em `sql/external_tables/`, com credencial em placeholder:

```
sql/external_tables/
  00_credential.template.sql    # versionado, com <PLACEHOLDERS>
  01_brz_sih_rd.sql
  02_brz_cnes.sql
  03_brz_sim_sinasc.sql
  99_validacao.sql
```
