#!/usr/bin/env bash
#
# dry-run do Lab 02 (PDN) - Streaming: Kinesis + Firehose + Spark
#
# Valida que o ambiente esta pronto SEM criar o stream (o shard gera custo).
# Somente chamadas read-only (sts/list/describe/get). Rode ANTES da aula.
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

echo "== Dry-run Lab 02 PDN (Kinesis + Firehose + Spark) | regiao: $REGION =="
echo "   (NAO cria stream; criar o stream/shard gera custo)"

# 1. AWS CLI
echo "[1/8] AWS CLI"
if command -v aws >/dev/null 2>&1; then
  pass "AWS CLI encontrada ($(aws --version 2>&1 | head -n1))"
else
  bad "AWS CLI nao encontrada. Instale a AWS CLI v2."
fi

# 2. Credencial
echo "[2/8] Credencial"
CALLER_JSON="$(aws sts get-caller-identity --output json 2>/dev/null)"
if [ -n "$CALLER_JSON" ]; then
  ARN="$(printf '%s' "$CALLER_JSON" | grep -o '"Arn"[^,]*' | cut -d'"' -f4)"
  pass "Credencial valida: $ARN"
else
  bad "Sem credencial valida. Rode 'aws configure'."
  ARN=""
fi

# 3. Usuario IAM (nao root)
echo "[3/8] Tipo de usuario (deve ser IAM, nao root)"
if [ -n "${ARN:-}" ]; then
  if printf '%s' "$ARN" | grep -q ':root'; then
    bad "Voce esta como ROOT. Use um usuario IAM."
  else
    pass "Usuario nao-root (ok)."
  fi
else
  info "Pulado (sem credencial)."
fi

# 4. Python 3 + boto3 (produtor)
echo "[4/8] Python 3 (produtor de eventos)"
if command -v python3 >/dev/null 2>&1; then
  pass "python3 encontrado ($(python3 --version 2>&1))"
  if python3 -c "import boto3" 2>/dev/null; then
    pass "boto3 disponivel."
  else
    info "boto3 ausente — o passo a passo instala com 'pip install boto3'."
  fi
else
  bad "python3 nao encontrado (necessario para o produtor)."
fi

# 5. Fonte de dados publica acessivel
echo "[5/8] Fonte de dados (openfootball, sem API key)"
URL="https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json"
if curl -fsI "$URL" >/dev/null 2>&1 || curl -fs -o /dev/null "$URL" 2>/dev/null; then
  pass "Dados de jogos acessiveis."
else
  info "Nao consegui acessar a fonte agora (rede?). Tenha um JSON local de backup."
fi

# 6. Permissoes Kinesis (read-only)
echo "[6/8] Permissoes Kinesis (read-only)"
if aws kinesis list-streams --region "$REGION" >/dev/null 2>&1; then
  pass "kinesis:ListStreams permitido."
else
  bad "Sem permissao para Kinesis (ListStreams)."
fi

# 7. Permissoes Firehose / S3 / IAM
echo "[7/8] Permissoes Firehose / S3 / IAM"
if aws firehose list-delivery-streams --region "$REGION" >/dev/null 2>&1; then
  pass "firehose:ListDeliveryStreams permitido."
else
  bad "Sem permissao para Firehose (ListDeliveryStreams)."
fi
if aws s3 ls >/dev/null 2>&1; then
  pass "s3:ListAllMyBuckets permitido."
else
  bad "Sem permissao para listar buckets S3."
fi
if aws iam list-roles --max-items 1 >/dev/null 2>&1; then
  pass "iam:ListRoles permitido (provavel poder criar a role do Firehose)."
else
  bad "Sem permissao de IAM para criar/vincular a role do Firehose."
fi

# 8. Application EMR Serverless do Lab A (para a parte Spark)
echo "[8/8] EMR Serverless do Lab A (parte Spark, no sabado)"
APPS="$(aws emr-serverless list-applications --region "$REGION" \
  --query 'applications[?name==`lab-pdn-emrs`].id' --output text 2>/dev/null)"
if [ -n "$APPS" ]; then
  pass "Application 'lab-pdn-emrs' encontrada ($APPS)."
else
  info "Application do Lab A nao encontrada. A parte Spark (passo 6) reusa ela — crie no Lab A."
fi

echo
echo "== Resultado: $ok ok, $fail com problema =="
if [ "$fail" -gt 0 ]; then
  echo "Resolva os itens ❌ antes da aula. Veja troubleshooting.md."
  exit 1
fi
echo "Ambiente pronto para o Lab 02 (PDN). Lembre-se: o shard gera custo; limpe ao final."
