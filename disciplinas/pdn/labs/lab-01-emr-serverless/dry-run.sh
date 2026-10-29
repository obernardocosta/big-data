#!/usr/bin/env bash
#
# dry-run do Lab 01 (PDN) - EMR Serverless (PySpark)
#
# Valida que o ambiente esta pronto SEM criar Application nem submeter job
# (o job e o que gera custo). Somente chamadas read-only (sts/list/get).
# Rode isto ANTES da aula.
#
# Uso:
#   ./dry-run.sh
#   REGION=us-east-2 RUNTIME_ROLE=EMRServerlessJobRole ./dry-run.sh
#
set -uo pipefail

REGION="${REGION:-us-east-1}"
RUNTIME_ROLE="${RUNTIME_ROLE:-EMRServerlessJobRole}"
ok=0
fail=0

pass() { printf '  \033[32m✅ %s\033[0m\n' "$1"; ok=$((ok+1)); }
bad()  { printf '  \033[31m❌ %s\033[0m\n' "$1"; fail=$((fail+1)); }
info() { printf '  \033[36mℹ️  %s\033[0m\n' "$1"; }

echo "== Dry-run Lab 01 PDN (EMR Serverless) | regiao alvo: $REGION =="
echo "   (NAO cria Application nem submete job; submeter job gera custo)"

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

# 4. Permissao EMR Serverless (read-only)
echo "[4/6] Permissao EMR Serverless (read-only)"
if aws emr-serverless list-applications --region "$REGION" >/dev/null 2>&1; then
  pass "emr-serverless:ListApplications permitido."
else
  bad "Sem permissao para EMR Serverless (ListApplications)."
fi

# 5. RuntimeRole do job (role POR JOB) ou permissao de IAM para cria-la
echo "[5/6] RuntimeRole do job ('$RUNTIME_ROLE')"
if aws iam get-role --role-name "$RUNTIME_ROLE" >/dev/null 2>&1; then
  pass "RuntimeRole '$RUNTIME_ROLE' existe."
  info "Garanta que ela da acesso ao bucket do lab (leitura do script, escrita da saida)."
elif aws iam list-roles --max-items 1 >/dev/null 2>&1; then
  info "Role nao existe, mas voce tem iam:ListRoles (provavel poder cria-la)."
else
  bad "Sem a RuntimeRole e sem permissao de IAM para cria-la."
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
echo "Ambiente pronto para o Lab 01 (PDN). Lembre-se: submeter o job gera custo."
