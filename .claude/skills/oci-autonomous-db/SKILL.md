---
name: oci-autonomous-db
description: Provisiona e opera o Oracle Autonomous Database do projeto — criação, wallet, conexão por SQLcl/sqlplus, usuários das camadas medallion, start/stop e escala. Use ao criar o ADB, baixar wallet, conectar no banco ou rodar SQL/PLSQL.
---

# Autonomous Database

O ADB hospeda o modelo medallion (Staging → Bronze → Silver → Gold → Marts) e é o motor do Select AI.

## Pré-requisitos

```bash
set -a; . .claude/oci.env; set +a
set -a; . .claude/oci.secrets; set +a    # ADB_ADMIN_PASSWORD, WALLET_PASSWORD
```

Nunca ecoe essas variáveis. Use-as direto nos comandos.

## Escolha do workload

Use **DW** (Data Warehouse), não OLTP/ATP. O projeto é analítico: agregações por região, séries mensais, cálculo de índice. `DW` já vem com paralelismo e otimizações de scan adequados a Parquet em External Table.

## Criar

Requisitos da senha de ADMIN: 12–30 caracteres, ao menos uma maiúscula, uma minúscula e um número, sem aspas duplas e **sem a string `admin`**.

Always Free:

```bash
$OCI_BIN db autonomous-database create \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --db-name SUSRADAR \
  --display-name "SUS Radar 360" \
  --db-workload DW \
  --is-free-tier true \
  --cpu-core-count 1 \
  --data-storage-size-in-tbs 1 \
  --admin-password "$ADB_ADMIN_PASSWORD" \
  --wait-for-state AVAILABLE
```

Conta paga ou trial (modelo ECPU, atual):

```bash
$OCI_BIN db autonomous-database create \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --db-name SUSRADAR \
  --display-name "SUS Radar 360" \
  --db-workload DW \
  --compute-model ECPU \
  --compute-count 2 \
  --data-storage-size-in-gbs 100 \
  --is-auto-scaling-enabled true \
  --license-model LICENSE_INCLUDED \
  --admin-password "$ADB_ADMIN_PASSWORD" \
  --wait-for-state AVAILABLE
```

`--db-name` aceita só letras e números, máximo 14 caracteres, e é **imutável**. `--wait-for-state AVAILABLE` bloqueia por vários minutos — rode em background.

Grave o OCID retornado em `oci.env`:

```bash
$OCI_BIN db autonomous-database list --compartment-id "$OCI_COMPARTMENT_ID" \
  --query "data[?\"display-name\"=='SUS Radar 360'].id | [0]" --raw-output
```

## Wallet

```bash
mkdir -p ~/.oci/wallets/susradar
$OCI_BIN db autonomous-database generate-wallet \
  --autonomous-database-id "$ADB_OCID" \
  --file ~/.oci/wallets/susradar/wallet.zip \
  --password "$WALLET_PASSWORD"
unzip -o ~/.oci/wallets/susradar/wallet.zip -d ~/.oci/wallets/susradar/
chmod 700 ~/.oci/wallets/susradar
```

A wallet **é credencial de acesso ao banco**. Fica fora do repositório, sempre — confirme que `**/wallet*.zip` e `.oci/` estão ignorados. Se alguém commitar uma wallet, ela precisa ser rotacionada (`generate-wallet` novo + rotate no console), não basta apagar o commit.

Serviços disponíveis no `tnsnames.ora`: `<dbname>_high`, `_medium`, `_low` (e `_tp`, `_tpurgent` em ATP). Para carga e transformação use `_medium`; para consultas do APEX, `_low`; `_high` só em job pesado isolado.

## Conectar

SQLcl é preferível ao sqlplus — aceita wallet direto e roda script sem instalação de client Oracle.

```bash
sql -cloudconfig ~/.oci/wallets/susradar/wallet.zip ADMIN@susradar_medium
```

Rodando um script:

```bash
sql -cloudconfig ~/.oci/wallets/susradar/wallet.zip \
    ADMIN/"$ADB_ADMIN_PASSWORD"@susradar_medium @sql/bronze/01_external_tables.sql
```

Se SQLcl não estiver instalado, python-oracledb em modo thin funciona sem client nativo:

```bash
.venv/bin/pip install oracledb
```

```python
import oracledb, os
con = oracledb.connect(
    user="ADMIN", password=os.environ["ADB_ADMIN_PASSWORD"],
    dsn="susradar_medium",
    config_dir=os.path.expanduser("~/.oci/wallets/susradar"),
    wallet_location=os.path.expanduser("~/.oci/wallets/susradar"),
    wallet_password=os.environ["WALLET_PASSWORD"])
```

Nunca hardcode senha em script versionado — leia de ambiente.

## Usuários das camadas

Não use ADMIN para os dados. Crie um dono por camada, para que o de/para de permissões espelhe o medallion:

```sql
CREATE USER bronze IDENTIFIED BY "<senha>" QUOTA UNLIMITED ON DATA;
GRANT DWROLE TO bronze;
GRANT EXECUTE ON DBMS_CLOUD TO bronze;
```

`DWROLE` é o papel padrão do ADB com o necessário para criar tabelas e views. `EXECUTE ON DBMS_CLOUD` é o que habilita External Table sobre Object Storage — sem isso a skill `oci-external-tables` falha com `ORA-00942` no pacote.

Repita para `silver`, `gold`. Registre as senhas em `.claude/oci.secrets`.

## Operação

```bash
# estado
$OCI_BIN db autonomous-database get --autonomous-database-id "$ADB_OCID" \
  --query "data.{nome:\"display-name\",estado:\"lifecycle-state\",ocpu:\"cpu-core-count\",gb:\"data-storage-size-in-gbs\"}" --output table

# parar / iniciar
$OCI_BIN db autonomous-database stop  --autonomous-database-id "$ADB_OCID" --wait-for-state STOPPED
$OCI_BIN db autonomous-database start --autonomous-database-id "$ADB_OCID" --wait-for-state AVAILABLE
```

**Always Free hiberna sozinho após 7 dias sem conexão e é reclamado após 90 dias inativo.** Num projeto acadêmico com semanas entre sprints isso apaga o banco. Se o ADB for free tier, avise o time e considere um toque semanal de conexão.

Em conta paga, parar o ADB entre sessões de trabalho economiza crédito — computação não é cobrada com o banco parado, só o armazenamento.

## Destruição

Nunca rode sem confirmação explícita do usuário na conversa:

```bash
$OCI_BIN db autonomous-database delete --autonomous-database-id "$ADB_OCID"
```
