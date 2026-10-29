#!/usr/bin/env bash
#
# dry-run do Lab 01 - AWS Glue Data Catalog
#
# Valida que o ambiente esta pronto para o lab SEM criar nada que gere custo.
# Use somente chamadas read-only (sts/list/describe/get). Rode isto ANTES da aula.
#
# Uso:
#   ./dry-run.sh                 # valida o ambiente
#   REGION=us-east-2 ./dry-run.sh  # valida em outra regiao
#
set -uo pipefail

REGION="${REGION:-us-east-1}"
ok=0
fail=0

pass() { printf '  \033[32m✅ %s\033[0m\n' "$1"; ok=$((ok+1)); }
bad()  { printf '  \033[31m❌ %s\033[0m\n' "$1"; fail=$((fail+1)); }
info() { printf '  \033[36mℹ️  %s\033[0m\n' "$1"; }

echo "== Dry-run Lab 01 (Glue Data Catalog) | regiao alvo: $REGION =="

# 1. AWS CLI instalada
echo "[1/5] AWS CLI"
if command -v aws >/dev/null 2>&1; then
  pass "AWS CLI encontrada ($(aws --version 2>&1 | head -n1))"
else
  bad "AWS CLI nao encontrada. Instale a AWS CLI v2."
fi

# 2. Credencial valida
echo "[2/5] Credencial"
CALLER_JSON="$(aws sts get-caller-identity --output json 2>/dev/null)"
if [ -n "$CALLER_JSON" ]; then
  ARN="$(printf '%s' "$CALLER_JSON" | grep -o '"Arn"[^,]*' | cut -d'"' -f4)"
  pass "Credencial valida: $ARN"
else
  bad "Sem credencial valida. Rode 'aws configure'."
  ARN=""
fi

# 3. Usuario IAM (nao root)
echo "[3/5] Tipo de usuario (deve ser IAM, nao root)"
if [ -n "${ARN:-}" ]; then
  if printf '%s' "$ARN" | grep -q ':root'; then
    bad "Voce esta como ROOT. Use um usuario IAM para o lab."
  else
    pass "Usuario nao-root (ok)."
  fi
else
  info "Pulado (sem credencial)."
fi

# 4. Regiao
echo "[4/5] Regiao configurada"
CUR_REGION="$(aws configure get region 2>/dev/null)"
if [ "$CUR_REGION" = "$REGION" ]; then
  pass "Regiao configurada = $REGION"
elif [ -n "$CUR_REGION" ]; then
  info "Regiao configurada ($CUR_REGION) difere do alvo ($REGION). Use --region ou exporte AWS_REGION."
else
  info "Nenhuma regiao default configurada. Passe --region nos comandos ou exporte AWS_REGION."
fi

# 5. Permissoes read-only em Glue e S3
echo "[5/5] Permissoes (read-only)"
if aws glue get-databases --region "$REGION" >/dev/null 2>&1; then
  pass "glue:GetDatabases permitido."
else
  bad "Sem permissao para glue:GetDatabases (precisa de acesso ao Glue)."
fi
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
echo "Ambiente pronto para o Lab 01."
