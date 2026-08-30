#!/usr/bin/env bash
# Sobe os Parquet de data/processed/ para o OCI Object Storage, no layout que as
# External Tables esperam.
#
#   ./scripts/upload_oci.sh          # sobe
#   ./scripts/upload_oci.sh --check  # so confere local x bucket, nao envia
#
# Requer .claude/oci.env preenchido (veja a skill oci-setup).

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

[[ -f .claude/oci.env ]] || { echo "ERRO: falta .claude/oci.env — rode a skill oci-setup"; exit 1; }
set -a; . .claude/oci.env; set +a
: "${OCI_BIN:=oci}" "${OCI_BUCKET_RAW:?}" "${OCI_COMPARTMENT_ID:?}" "${OCI_NAMESPACE:?}"

# --namespace sempre explicito: a resolucao implicita do CLI falhou nesta tenancy
# com BucketNotFound em list_objects, mesmo com o bucket existindo e put_object
# funcionando. Atencao: e opcao do SUBCOMANDO ("os bucket get ... --namespace X"),
# nao do grupo "os" — na posicao errada o CLI sai com codigo 2.
NS=(--namespace "$OCI_NAMESPACE")
OS=($OCI_BIN os)

declare -A PREFIXO=(
  [SIHSUS]=processed/sihsus
  [CNES]=processed/cnes
  [SIM]=processed/sim
  [SINASC]=processed/sinasc
)

# Conta objetos sob um prefixo. Nao usa --query "length(data)": num bucket vazio o
# CLI devolve data=null e o JMESPath estoura com JMESPathTypeError.
contar_bucket() {
  "${OS[@]}" object list "${NS[@]}" --bucket-name "$OCI_BUCKET_RAW" \
      --prefix "$1" --all 2>/dev/null \
    | .venv/bin/python -c "
import json, sys
t = sys.stdin.read().strip()
print(len(json.loads(t).get('data') or []) if t else 'ERRO')"
}

conferir() {
  local falhou=0 tl=0 tb=0 l b
  printf "%-9s %6s %7s\n" sistema local bucket
  for sis in SIHSUS CNES SIM SINASC; do
    l=$(find "data/processed/$sis" -name '*.parquet' 2>/dev/null | wc -l)
    b=$(contar_bucket "${PREFIXO[$sis]}/")
    if [[ "$l" == "$b" ]]; then
      printf "%-9s %6s %7s\n" "$sis" "$l" "$b"
    else
      printf "%-9s %6s %7s   <-- DIVERGENTE\n" "$sis" "$l" "$b"
      falhou=1                      # fora de subshell, senao a atribuicao se perde
    fi
    [[ "$b" =~ ^[0-9]+$ ]] && { tl=$((tl+l)); tb=$((tb+b)); }
  done
  printf "%-9s %6d %7d\n" TOTAL "$tl" "$tb"
  return $falhou
}

if [[ "${1:-}" == "--check" ]]; then conferir; exit $?; fi

# bucket — NoPublicAccess e obrigatorio: sao microdados de saude
if "${OS[@]}" bucket get "${NS[@]}" --bucket-name "$OCI_BUCKET_RAW" >/dev/null 2>&1; then
  echo "bucket $OCI_BUCKET_RAW ja existe"
else
  echo "criando bucket $OCI_BUCKET_RAW"
  "${OS[@]}" bucket create "${NS[@]}" \
    --compartment-id "$OCI_COMPARTMENT_ID" \
    --name "$OCI_BUCKET_RAW" \
    --storage-tier Standard \
    --versioning Disabled \
    --public-access-type NoPublicAccess >/dev/null
  # o bucket nao fica visivel no endpoint de objetos imediatamente
  for i in $(seq 30); do
    "${OS[@]}" object list "${NS[@]}" --bucket-name "$OCI_BUCKET_RAW" >/dev/null 2>&1 && break
    echo "  aguardando o bucket ficar visivel... ($i)"; sleep 2
  done
fi

# bulk-upload imprime "Uploaded X" no progresso mesmo quando o envio falha; o
# resultado autoritativo e o mapa upload-failures do JSON. Nunca confie no texto.
subir() {
  local sis=$1 saida
  saida=$("${OS[@]}" object bulk-upload "${NS[@]}" \
    --bucket-name "$OCI_BUCKET_RAW" \
    --src-dir "data/processed/$sis" \
    --object-prefix "${PREFIXO[$sis]}/" \
    --content-type auto \
    --parallel-upload-count 8 \
    --no-overwrite 2>&1) || true
  # o JSON vem depois das linhas de progresso "Uploaded ..."
  local falhas
  falhas=$(printf '%s' "$saida" | .venv/bin/python -c "
import json, sys, re
t = sys.stdin.read()
i = t.find('\n{')
if i < 0: print('SEM_JSON'); sys.exit()
try: d = json.loads(t[i+1:])
except Exception: print('JSON_INVALIDO'); sys.exit()
f, o = d.get('upload-failures') or {}, d.get('uploaded-objects') or {}
print(f'{len(f)} {len(o)}')")
  read -r n_falhas n_ok <<< "$falhas"
  if [[ "$n_falhas" == "0" ]]; then
    echo "  ok — $n_ok arquivo(s)"
  else
    echo "  FALHOU: $n_falhas falha(s), $n_ok enviado(s)"
    printf '%s' "$saida" | grep -oE "'code': '[^']+'|'message': \"[^\"]+\"" | sort -u | head -3
    return 1
  fi
}

for sis in SIHSUS CNES SIM SINASC; do
  [[ -d "data/processed/$sis" ]] || { echo "pulando $sis (sem dados locais)"; continue; }
  echo "--- $sis -> ${PREFIXO[$sis]}/ ---"
  subir "$sis"
done

for f in manifesto catalogo; do
  "${OS[@]}" object put "${NS[@]}" --bucket-name "$OCI_BUCKET_RAW" \
    --file "data/$f.csv" --name "processed/_$f.csv" --force >/dev/null
done
echo "metadados da carga enviados (_manifesto.csv, _catalogo.csv)"

echo
conferir

mkdir -p sql/01_bronze
{
  echo "# Gerado por scripts/upload_oci.sh — substitua nos arquivos sql/01_bronze/*.sql"
  echo "REGIAO=$OCI_REGION"
  echo "NAMESPACE=$OCI_NAMESPACE"
  echo "BUCKET=$OCI_BUCKET_RAW"
  echo
  for sis in SIHSUS CNES SIM SINASC; do
    echo "$sis: https://objectstorage.$OCI_REGION.oraclecloud.com/n/$OCI_NAMESPACE/b/$OCI_BUCKET_RAW/o/${PREFIXO[$sis]}/*.parquet"
  done
} > sql/01_bronze/uris.txt
echo
echo "URIs em sql/01_bronze/uris.txt"
