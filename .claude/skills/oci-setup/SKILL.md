---
name: oci-setup
description: Instala o OCI CLI, autentica na tenancy, descobre namespace e compartment, e grava o arquivo de configuração do projeto (.claude/oci.env). Use antes de qualquer operação na OCI, ou quando um comando oci falhar com erro de autenticação/autorização (NotAuthenticated, NotAuthorizedOrNotFound, 401, 404).
---

# Setup e autenticação na OCI

Prepara a máquina local para operar a OCI do projeto SUS Radar 360. Rode uma vez; depois `oci.env` é a fonte de verdade dos identificadores.

## Regra de ouro

**Nunca peça, leia, ecoe ou escreva no chat:** chave privada (`~/.oci/*.pem`), passphrase, auth token, senha de ADMIN do banco ou conteúdo de wallet. Se precisar de um segredo em um comando, leia de arquivo com `$(cat ...)` dentro do próprio comando — sem `echo`, sem `cat` isolado.

## 1. Verificar o que já existe

```bash
which oci && oci --version
ls -la ~/.oci 2>/dev/null
cat .claude/oci.env 2>/dev/null
```

Se `oci.env` já existir e `oci os ns get` responder, o setup está feito — pare aqui.

## 2. Instalar o CLI

O instalador é interativo e pede confirmação de caminhos; **peça para o usuário rodar**, não rode você:

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
```

**Neste projeto o CLI ja esta instalado no venv** (`.venv/bin/oci`), entao esse passo esta feito:

```bash
.venv/bin/oci --version
```

Por isso `oci.env` traz `OCI_BIN=.venv/bin/oci`.

## 3. Autenticar

**A autenticação é sempre do usuário, nunca sua.** Instrua e espere.

Preferido — gera a chave API e faz upload dela automaticamente via browser:

```bash
oci setup bootstrap
```

Plano B, se o browser não abrir no WSL:

```bash
oci setup config
```

Pede tenancy OCID, user OCID, região e gera o par de chaves. Depois o usuário sobe `~/.oci/oci_api_key_public.pem` no console em **Profile → API keys** e confirma o fingerprint.

Evite `oci session authenticate`: o token expira em 1 hora e força re-autenticação por browser no meio de uma sequência de operações. Se a tenancy só permitir esse modo, todo comando precisa de `--auth security_token` e a skill deve renovar com `oci session refresh` antes de operações longas.

## 4. Validar e descobrir os identificadores

```bash
oci iam region list --output table          # autenticação funciona?
oci os ns get                               # namespace do Object Storage
oci iam compartment list --all --output table --query "data[].{nome:name,id:id,estado:\"lifecycle-state\"}"
```

Se `iam region list` falhar, o problema é autenticação (chave/fingerprint). Se ele passar mas `compartment list` falhar, o problema é **policy** — o usuário não tem permissão, e isso precisa ser resolvido com quem administra a tenancy. Não tente contornar.

Compartment dedicado, se houver permissão:

```bash
oci iam compartment create \
  --compartment-id <ocid-do-pai> \
  --name sus-radar-360 \
  --description "Challenge Oracle x FIAP 2026 - grupo GreatMinds"
```

## 5. Gravar `.claude/oci.env`

Ha um template versionado — copie e preencha:

```bash
cp .claude/oci.env.example .claude/oci.env
```

Conteudo esperado:

```bash
cat > .claude/oci.env <<'EOF'
# Configuração OCI do SUS Radar 360 — sem segredos, mas fora do git
OCI_BIN=oci
OCI_PROFILE=DEFAULT
OCI_REGION=<ex: sa-saopaulo-1>
OCI_NAMESPACE=<saída de: oci os ns get>
OCI_COMPARTMENT_ID=ocid1.compartment.oc1..<...>
OCI_TENANCY_ID=ocid1.tenancy.oc1..<...>

# Object Storage
OCI_BUCKET_RAW=datasus-raw
OCI_BUCKET_STAGING=datasus-staging

# Autonomous Database (preencher após provisionar)
ADB_OCID=
ADB_NAME=SUSRADAR
ADB_WALLET_DIR=~/.oci/wallets/susradar
EOF
```

Confirme que `.claude/oci.env`, `.claude/oci.secrets` e `**/wallet*.zip` estão no `.gitignore`. Se não estiverem, adicione.

Para segredos:

```bash
touch .claude/oci.secrets && chmod 600 .claude/oci.secrets
```

O usuário preenche esse arquivo à mão (`ADB_ADMIN_PASSWORD=...`, `WALLET_PASSWORD=...`). Você o carrega com `set -a; . .claude/oci.secrets; set +a` e usa as variáveis — nunca imprime.

## 6. Checagem final

```bash
set -a; . .claude/oci.env; set +a
$OCI_BIN os bucket list --compartment-id "$OCI_COMPARTMENT_ID" --output table
$OCI_BIN db autonomous-database list --compartment-id "$OCI_COMPARTMENT_ID" --output table 2>/dev/null || echo "sem ADB ainda (ok) ou sem permissão"
```

## Limites de conta (verificar antes de dimensionar)

| Recurso | Always Free | Free Trial (30 dias) |
|---|---|---|
| Object Storage | 20 GB total | 200 GB de crédito |
| Autonomous Database | 2 instâncias, 1 OCPU / 20 GB cada | shapes maiores com crédito |
| Flag de criação do ADB | `--is-free-tier true` | pode escolher OCPU/ECPU |

Volume atual do projeto: ~1,5 GB de DBC bruto + ~700 MB de Parquet. Cabe no Always Free, mas subir o `data/raw/` **e** o `data/processed/` consome metade da cota — prefira subir só o Parquet (ver skill `oci-object-storage`).
