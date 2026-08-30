---
name: oci-object-storage
description: Cria buckets no OCI Object Storage e sobe os arquivos do data lake (Parquet/DBC/CSV) com bulk-upload, conferindo integridade e montando as URIs que as External Tables vão consumir. Use ao criar bucket, subir/listar/remover objetos, gerar PAR ou montar file_uri_list.
---

# Object Storage — buckets e carga dos arquivos

Camada de ingestão do SUS Radar 360: os arquivos locais em `data/` viram objetos que o Autonomous Database lê por External Table.

## Pré-requisitos

```bash
set -a; . .claude/oci.env; set +a
```

Sem `oci.env`, rode a skill `oci-setup` antes.

## Layout de buckets

O deck definiu quatro prefixos. Implemente como **dois buckets com prefixos internos**, não quatro buckets — simplifica policy e PAR:

```
datasus-raw/
  raw/sihsus/RDSP2406.dbc ...      # opcional, só se houver cota
  processed/sihsus/RDSP2406.parquet
  processed/cnes/LTSP2607.parquet
  processed/sim/DOSP2023.parquet
  processed/sinasc/DNSP2022.parquet
  aux/                             # CID-10, SIGTAP, de/para municipio->regiao
  socio/                           # CSVs do IBGE
datasus-staging/                   # saídas intermediárias do processamento
```

**Suba o Parquet, não o DBC.** O DBC é formato proprietário do DATASUS: o Autonomous Database não lê, e ele consome o dobro da cota. O bruto fica local como evidência de proveniência. Só suba `raw/` se o time exigir rastreabilidade na nuvem e a cota permitir.

## Criar buckets

```bash
$OCI_BIN os bucket create \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --name "$OCI_BUCKET_RAW" \
  --storage-tier Standard \
  --versioning Disabled \
  --public-access-type NoPublicAccess
```

`NoPublicAccess` é obrigatório: são microdados de saúde. Mesmo anonimizados, bucket público é inaceitável no contexto do projeto. O acesso do banco se dá por credencial DBMS_CLOUD, não por URL pública.

Conferir:

```bash
$OCI_BIN os bucket list --compartment-id "$OCI_COMPARTMENT_ID" --output table
```

## Upload em massa

```bash
$OCI_BIN os object bulk-upload \
  --bucket-name "$OCI_BUCKET_RAW" \
  --src-dir data/processed/SIHSUS \
  --object-prefix processed/sihsus/ \
  --content-type auto \
  --parallel-upload-count 8 \
  --no-overwrite
```

Repita por sistema (`CNES`, `SIM`, `SINASC`), trocando `--src-dir` e `--object-prefix`.

- `--no-overwrite` protege contra reenvio acidental; use `--overwrite` só em recarga deliberada.
- `--parallel-upload-count 8` é seguro em link doméstico; suba para 16 se a banda aguentar.
- Upload é demorado — rode em background e monitore.
- Se a conexão cair no meio, `bulk-upload` com `--no-overwrite` retoma pulando o que já subiu.

Para um arquivo só:

```bash
$OCI_BIN os object put --bucket-name "$OCI_BUCKET_RAW" \
  --file data/manifesto.csv --name processed/manifesto.csv --force
```

## Conferir a carga

```bash
# contagem e tamanho por prefixo
$OCI_BIN os object list --bucket-name "$OCI_BUCKET_RAW" --prefix processed/ --all \
  --query "data[].{nome:name,bytes:size}" --output table

# total de objetos
$OCI_BIN os object list --bucket-name "$OCI_BUCKET_RAW" --prefix processed/ --all --query "length(data)"
```

**Sempre valide contra o local**, não confie no exit code:

```bash
find data/processed -name '*.parquet' | wc -l   # deve bater com a contagem acima
```

Se divergir, liste os dois lados e compare nomes — não resuba tudo às cegas.

## URIs para as External Tables

Formato nativo:

```
https://objectstorage.<região>.oraclecloud.com/n/<namespace>/b/<bucket>/o/<objeto>
```

Montar com wildcard, que é o que `DBMS_CLOUD.CREATE_EXTERNAL_TABLE` consome:

```bash
echo "https://objectstorage.$OCI_REGION.oraclecloud.com/n/$OCI_NAMESPACE/b/$OCI_BUCKET_RAW/o/processed/sihsus/*.parquet"
```

Gere e registre em `sql/external_tables/uris.txt` para o pessoal da modelagem não ter que remontar à mão.

## Pre-Authenticated Request (PAR)

Só quando algo externo (Power BI, colega sem acesso à tenancy) precisar ler sem credencial:

```bash
$OCI_BIN os preauth-request create \
  --bucket-name "$OCI_BUCKET_RAW" \
  --name par-leitura-temporaria \
  --access-type AnyObjectRead \
  --time-expires "$(date -u -d '+7 days' +%Y-%m-%dT%H:%M:%SZ)"
```

A URL completa **só aparece uma vez, na criação**. Trate como segredo: não escreva em arquivo versionado, não cole no chat, e sempre ponha prazo curto. Prefira dar acesso IAM ao colega em vez de PAR.

## Remoção

Confirme com o usuário antes de qualquer delete — recarregar significa horas de download do DATASUS de novo.

```bash
$OCI_BIN os object bulk-delete --bucket-name "$OCI_BUCKET_RAW" --prefix processed/sihsus/ --dry-run
```

Rode sempre com `--dry-run` primeiro e mostre a saída antes de executar de verdade.
