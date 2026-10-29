#!/usr/bin/env bash
#
# dry-run do Lab 03 - Consultas no Amazon Athena
#
# Valida que o ambiente esta pronto para o lab SEM gerar custo relevante.
# Somente chamadas read-only (sts/list/describe/get). Rode isto ANTES da aula.
#
# Uso:
#   ./dry-run.sh
#   REGION=us-east-2 DB=futebol_auto ./dry-run.sh
#
set -uo pipefail

REGION="${REGION:-us-east-1}"
DB="${DB:-futebol}"
ok=0
fail=0

pass() { printf '  \033[32m✅ %s\033[0m\n' "$1"; ok=$((ok+1)); }
bad()  { printf '  \033[31m❌ %s\033[0m\n' "$1"; fail=$((fail+1)); }
info() { printf '  \033[36mℹ️  %s\033[0m\n' "$1"; }

echo "== Dry-run Lab 03 (Athena) | regiao alvo: $REGION | database: $DB =="

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

# 4. Permissoes read-only em Athena / S3
echo "[4/6] Permissoes Athena / S3 (read-only)"
if aws athena list-work-groups --region "$REGION" >/dev/null 2>&1; then
  pass "athena:ListWorkGroups permitido."
else
  bad "Sem permissao para Athena (athena:ListWorkGroups)."
fi
if aws s3 ls >/dev/null 2>&1; then
  pass "s3:ListAllMyBuckets permitido."
else
  bad "Sem permissao para listar buckets S3."
fi

# 5. Existe uma tabela catalogada no database alvo?
echo "[5/6] Tabela catalogada no database '$DB' (saida do Lab 01/02)"
TABLES="$(aws glue get-tables --database-name "$DB" --region "$REGION" \
  --query 'TableList[].Name' --output text 2>/dev/null)"
if [ -n "$TABLES" ]; then
  pass "Tabelas encontradas em '$DB': $TABLES"
else
  bad "Nenhuma tabela em '$DB'. Rode o Lab 01 ou 02 antes, ou ajuste a var DB."
fi

# 6. Permissao de escrever resultados no S3 (bucket de results)
echo "[6/6] Permissao de criar o bucket de query results"
if aws s3api list-buckets >/dev/null 2>&1; then
  pass "Acesso ao S3 ok (provavel poder criar o bucket de results)."
else
  bad "Sem acesso ao S3 para criar/usar o bucket de query results."
fi

echo
echo "== Resultado: $ok ok, $fail com problema =="
if [ "$fail" -gt 0 ]; then
  echo "Resolva os itens marcados com ❌ antes da aula. Veja troubleshooting.md."
  exit 1
fi
echo "Ambiente pronto para o Lab 03."
