#!/usr/bin/env bash
#
# dry-run do Lab 04 - Particionamento no S3 (+ Crawler + Athena)
#
# Valida que o ambiente esta pronto para o lab SEM gerar custo relevante.
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

echo "== Dry-run Lab 04 (Particionamento) | regiao alvo: $REGION =="

# 1. AWS CLI
echo "[1/7] AWS CLI"
if command -v aws >/dev/null 2>&1; then
  pass "AWS CLI encontrada ($(aws --version 2>&1 | head -n1))"
else
  bad "AWS CLI nao encontrada. Instale a AWS CLI v2."
fi

# 2. Credencial
echo "[2/7] Credencial"
CALLER_JSON="$(aws sts get-caller-identity --output json 2>/dev/null)"
if [ -n "$CALLER_JSON" ]; then
  ARN="$(printf '%s' "$CALLER_JSON" | grep -o '"Arn"[^,]*' | cut -d'"' -f4)"
  pass "Credencial valida: $ARN"
else
  bad "Sem credencial valida. Rode 'aws configure'."
  ARN=""
fi

# 3. Usuario IAM (nao root)
echo "[3/7] Tipo de usuario (deve ser IAM, nao root)"
if [ -n "${ARN:-}" ]; then
  if printf '%s' "$ARN" | grep -q ':root'; then
    bad "Voce esta como ROOT. Use um usuario IAM para o lab."
  else
    pass "Usuario nao-root (ok)."
  fi
else
  info "Pulado (sem credencial)."
fi

# 4. Permissoes Glue (read-only)
echo "[4/7] Permissoes Glue (read-only)"
if aws glue get-crawlers --region "$REGION" >/dev/null 2>&1; then
  pass "glue:GetCrawlers permitido."
else
  bad "Sem permissao para glue:GetCrawlers."
fi

# 5. Permissoes Athena (read-only)
echo "[5/7] Permissoes Athena (read-only)"
if aws athena list-work-groups --region "$REGION" >/dev/null 2>&1; then
  pass "athena:ListWorkGroups permitido."
else
  bad "Sem permissao para Athena (athena:ListWorkGroups)."
fi

# 6. S3
echo "[6/7] Permissoes S3"
if aws s3 ls >/dev/null 2>&1; then
  pass "s3:ListAllMyBuckets permitido."
else
  bad "Sem permissao para listar buckets S3."
fi

# 7. Role de servico do Glue (reaproveitada do Lab 02) ou permissao de IAM
echo "[7/7] Role do Glue (GlueCrawlerLabRole) ou permissao de IAM para cria-la"
if aws iam get-role --role-name GlueCrawlerLabRole >/dev/null 2>&1; then
  pass "Role GlueCrawlerLabRole ja existe (reaproveitavel do Lab 02)."
elif aws iam list-roles --max-items 1 >/dev/null 2>&1; then
  info "Role nao existe, mas voce tem iam:ListRoles (provavel poder cria-la)."
else
  bad "Sem a role e sem permissao de IAM. Crie a role como no Lab 02 (passo 2)."
fi

# Dados reais (openfootball) + python3 para gerar o CSV
echo "[extra] Dados reais (openfootball) + python3"
if command -v python3 >/dev/null 2>&1; then
  pass "python3 encontrado."
else
  bad "python3 nao encontrado (usado para gerar o CSV a partir do JSON)."
fi
if curl -fs -o /dev/null "https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json" 2>/dev/null; then
  pass "Fonte de dados acessivel (openfootball)."
else
  info "Fonte nao acessivel agora (rede?). Tenha um JSON/CSV local de backup."
fi

echo
echo "== Resultado: $ok ok, $fail com problema =="
if [ "$fail" -gt 0 ]; then
  echo "Resolva os itens marcados com ❌ antes da aula. Veja troubleshooting.md."
  exit 1
fi
echo "Ambiente pronto para o Lab 04."
