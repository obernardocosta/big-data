#!/usr/bin/env bash
#
# dry-run do Lab 02 (PDN) - Amazon SageMaker
#
# Valida que o ambiente esta pronto SEM treinar modelo nem criar endpoint
# (o que gera custo, especialmente o ENDPOINT). Somente chamadas read-only.
# Rode isto ANTES da aula.
#
# Uso:
#   ./dry-run.sh
#   REGION=us-east-2 SM_ROLE=SageMakerExecutionRole ./dry-run.sh
#
set -uo pipefail

REGION="${REGION:-us-east-1}"
SM_ROLE="${SM_ROLE:-SageMakerExecutionRole}"
ok=0
fail=0

pass() { printf '  \033[32m✅ %s\033[0m\n' "$1"; ok=$((ok+1)); }
bad()  { printf '  \033[31m❌ %s\033[0m\n' "$1"; fail=$((fail+1)); }
info() { printf '  \033[36mℹ️  %s\033[0m\n' "$1"; }

echo "== Dry-run Lab 02 PDN (SageMaker) | regiao alvo: $REGION =="
echo "   (NAO treina nem cria endpoint; o ENDPOINT cobra enquanto existir)"

# 1. AWS CLI
echo "[1/6] AWS CLI"
if command -v aws >/dev/null 2>&1; then
  pass "AWS CLI encontrada ($(aws --version 2>&1 | head -n1))"
else
  bad "AWS CLI nao encontrada. Instale a AWS CLI v2."
fi

# 2. Credencial
echo "[2/6] Credencial"
CALLER_JSON="$(aws sts get-caller-identity --output json 2>/dev/null)"
if [ -n "$CALLER_JSON" ]; then
  ARN="$(printf '%s' "$CALLER_JSON" | grep -o '"Arn"[^,]*' | cut -d'"' -f4)"
  pass "Credencial valida: $ARN"
else
  bad "Sem credencial valida. Rode 'aws configure'."
  ARN=""
fi

# 3. Usuario IAM (nao root)
echo "[3/6] Tipo de usuario (deve ser IAM, nao root)"
if [ -n "${ARN:-}" ]; then
  if printf '%s' "$ARN" | grep -q ':root'; then
    bad "Voce esta como ROOT. Use um usuario IAM para o lab."
  else
    pass "Usuario nao-root (ok)."
  fi
else
  info "Pulado (sem credencial)."
fi

# 4. Permissao SageMaker (read-only)
echo "[4/6] Permissao SageMaker (read-only)"
if aws sagemaker list-endpoints --region "$REGION" >/dev/null 2>&1; then
  pass "sagemaker:ListEndpoints permitido."
else
  bad "Sem permissao para SageMaker (ListEndpoints)."
fi

# 5. Execution role do SageMaker
echo "[5/6] Execution role do SageMaker ('$SM_ROLE')"
if aws iam get-role --role-name "$SM_ROLE" >/dev/null 2>&1; then
  pass "Execution role '$SM_ROLE' existe."
  info "Garanta acesso ao bucket do lab (dados de treino + artefatos do modelo)."
elif aws iam list-roles --max-items 1 >/dev/null 2>&1; then
  info "Role nao existe, mas voce tem iam:ListRoles (provavel poder cria-la)."
else
  bad "Sem a execution role e sem permissao de IAM para cria-la."
fi

# 6. S3
echo "[6/6] Permissoes S3"
if aws s3 ls >/dev/null 2>&1; then
  pass "s3:ListAllMyBuckets permitido."
else
  bad "Sem permissao para listar buckets S3."
fi

echo
echo "== Resultado: $ok ok, $fail com problema =="
if [ "$fail" -gt 0 ]; then
  echo "Resolva os itens marcados com ❌ antes da aula. Veja troubleshooting.md."
  exit 1
fi
echo "Ambiente pronto para o Lab 02 (PDN). LEMBRE-SE: apague o ENDPOINT ao terminar."
