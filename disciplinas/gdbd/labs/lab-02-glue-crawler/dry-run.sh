#!/usr/bin/env bash
#
# dry-run do Lab 02 - AWS Glue Crawler
#
# Valida que o ambiente esta pronto para o lab SEM criar nada que gere custo.
# Somente chamadas read-only (sts/list/describe/get). Rode isto ANTES da aula.
#
# Uso:
#   ./dry-run.sh
#   ./dry-run.sh --check-account   # 1a vez numa conta: detecta bloqueio do Glue
#   REGION=us-east-2 ./dry-run.sh
#
set -uo pipefail

REGION="${REGION:-us-east-1}"
# --check-account: liga a sonda de bloqueio de conta no Glue (secao [conta]).
# Ela chama glue:CreateCrawler com uma role inexistente: a chamada sempre
# falha e nada e criado, mas por ser um "create" fica desligada por padrao.
CHECK_ACCOUNT=0
for arg in "$@"; do [ "$arg" = "--check-account" ] && CHECK_ACCOUNT=1; done
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

# Dados reais (repo data) + python3 para gerar o CSV
# [conta] Glue liberado para criar Crawler/Job? Contas novas podem vir com um
# bloqueio de conta ("Account <id> is denied access") que NENHUMA permissao IAM
# resolve, e que as checagens read-only acima nao enxergam. A sonda tenta criar
# um crawler com uma role inexistente: a AWS checa a conta ANTES da role, entao
# nada e criado em nenhum dos casos (e, por garantia, apagamos se existir).
echo "[conta] Glue liberado para criar Crawler/Job (sonda, nao cria nada)"
if [ "$CHECK_ACCOUNT" = 1 ]; then
PROBE_ACC="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)"
if [ -n "$PROBE_ACC" ]; then
  PROBE_OUT="$(aws glue create-crawler --name dryrun-probe-glue \
    --role "arn:aws:iam::${PROBE_ACC}:role/dryrun-probe-inexistente" \
    --database-name default --region "$REGION" \
    --targets '{"S3Targets":[{"Path":"s3://dryrun-probe-inexistente/x/"}]}' 2>&1)"
  aws glue delete-crawler --name dryrun-probe-glue --region "$REGION" >/dev/null 2>&1
  if printf '%s' "$PROBE_OUT" | grep -q "is denied access"; then
    bad "Conta BLOQUEADA no Glue ('Account is denied access'). Crawler e Glue Job nao vao funcionar."
    info "Nao e IAM: abra um caso no AWS Support > 'Account and billing' (gratis, sem plano pago)"
    info "pedindo a liberacao do AWS Glue em $REGION. Leva de horas a dias: faca com antecedencia."
  else
    pass "Conta liberada para criar recursos no Glue."
  fi
else
  info "Pulado (sem credencial)."
fi
else
  info "Bloqueio de conta no Glue NAO verificado. Na 1a vez numa conta, rode: ./dry-run.sh --check-account"
fi

echo "[extra] Dados reais (repo data) + python3"
if command -v python3 >/dev/null 2>&1; then
  pass "python3 encontrado."
else
  bad "python3 nao encontrado (usado para gerar o CSV a partir do JSON)."
fi
if curl -fs -o /dev/null "https://raw.githubusercontent.com/obernardocosta/data/main/football/premier-league/2024-25/en.1.json" 2>/dev/null; then
  pass "Fonte de dados acessivel (repo data)."
else
  info "Fonte nao acessivel agora (rede?). Tenha um JSON/CSV local de backup."
fi

echo
echo "== Resultado: $ok ok, $fail com problema =="
if [ "$fail" -gt 0 ]; then
  echo "Resolva os itens marcados com ❌ antes da aula. Veja troubleshooting.md."
  exit 1
fi
echo "Ambiente pronto para o Lab 02."
