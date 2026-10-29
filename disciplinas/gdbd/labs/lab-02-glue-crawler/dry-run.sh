#!/usr/bin/env bash
#
# dry-run do Lab 02 - AWS Glue Crawler
#
# Valida que o ambiente esta pronto para o lab SEM criar nada que gere custo.
# Somente chamadas read-only (sts/list/describe/get). Rode isto ANTES da aula.
#
# Uso:
#   ./dry-run.sh
#   REGION=us-east-2 ./dry-run.sh
#
set -uo pipefail

REGION="${REGION:-us-east-1}"
ok=0
fail=0

pass() { printf '  \033[32m✅ %s\033[0m\n' "$1"; ok=$((ok+1)); }
bad()  { printf '  \033[31m❌ %s\033[0m\n' "$1"; fail=$((fail+1)); }
info() { printf '  \033[36mℹ️  %s\033[0m\n' "$1"; }

echo "== Dry-run Lab 02 (Glue Crawler) | regiao alvo: $REGION =="

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

# 4. Regiao
echo "[4/6] Regiao configurada"
CUR_REGION="$(aws configure get region 2>/dev/null)"
if [ "$CUR_REGION" = "$REGION" ]; then
  pass "Regiao configurada = $REGION"
elif [ -n "$CUR_REGION" ]; then
  info "Regiao configurada ($CUR_REGION) difere do alvo ($REGION)."
else
  info "Nenhuma regiao default configurada. Exporte AWS_REGION ou use --region."
fi

# 5. Permissoes read-only em Glue e S3
echo "[5/6] Permissoes Glue / S3 (read-only)"
if aws glue get-crawlers --region "$REGION" >/dev/null 2>&1; then
  pass "glue:GetCrawlers permitido."
else
  bad "Sem permissao para glue:GetCrawlers."
fi
if aws s3 ls >/dev/null 2>&1; then
  pass "s3:ListAllMyBuckets permitido."
else
  bad "Sem permissao para listar buckets S3."
fi

# 6. Permissao de IAM (o lab cria uma role para o Glue)
echo "[6/6] Permissao IAM (o lab cria uma role para o Glue assumir)"
if aws iam list-roles --max-items 1 >/dev/null 2>&1; then
  pass "iam:ListRoles permitido (provavel poder criar role)."
else
  bad "Sem permissao de IAM. Voce precisa poder criar/vincular uma role de servico do Glue."
fi

echo
echo "== Resultado: $ok ok, $fail com problema =="
if [ "$fail" -gt 0 ]; then
  echo "Resolva os itens marcados com ❌ antes da aula. Veja troubleshooting.md."
  exit 1
fi
echo "Ambiente pronto para o Lab 02."
