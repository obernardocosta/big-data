#!/usr/bin/env bash
#
# dry-run do Lab C (PDN) - Amazon SageMaker
#
# Valida que o ambiente esta pronto SEM treinar modelo nem criar endpoint
# (o que gera custo, especialmente o ENDPOINT). Somente chamadas read-only.
#
# Alem de credencial/permissoes, verifica as QUOTAS de instancia de ML da conta.
# Contas novas costumam vir com quota 0 para Training Job e Batch Transform, e
# o pedido de aumento leva de horas a dias. Rode isto com SEMANAS de antecedencia
# (e de novo na vespera).
#
# Uso:
#   ./dry-run.sh
#   REGION=us-east-2 SM_ROLE=SageMakerExecutionRole ./dry-run.sh
#   TRAIN_TYPE=ml.m5.large ENDPOINT_TYPE=ml.t2.medium ./dry-run.sh
#
set -uo pipefail

REGION="${REGION:-us-east-1}"
SM_ROLE="${SM_ROLE:-SageMakerExecutionRole}"
# Tipos de instancia usados no lab (manter alinhado com o passo-a-passo.md)
NOTEBOOK_TYPE="${NOTEBOOK_TYPE:-ml.t3.medium}"
TRAIN_TYPE="${TRAIN_TYPE:-ml.m5.large}"
TRANSFORM_TYPE="${TRANSFORM_TYPE:-ml.m5.large}"
ENDPOINT_TYPE="${ENDPOINT_TYPE:-ml.t2.medium}"
ok=0
warn=0
fail=0

pass()  { printf '  \033[32m✅ %s\033[0m\n' "$1"; ok=$((ok+1)); }
warnf() { printf '  \033[33m⚠️  %s\033[0m\n' "$1"; warn=$((warn+1)); }
bad()   { printf '  \033[31m❌ %s\033[0m\n' "$1"; fail=$((fail+1)); }
info()  { printf '  \033[36mℹ️  %s\033[0m\n' "$1"; }

echo "== Dry-run Lab C PDN (SageMaker) | regiao alvo: $REGION =="
echo "   (NAO treina nem cria endpoint; o ENDPOINT cobra enquanto existir)"

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

# 4. Permissao SageMaker (read-only)
echo "[4/7] Permissao SageMaker (read-only)"
if aws sagemaker list-endpoints --region "$REGION" >/dev/null 2>&1; then
  pass "sagemaker:ListEndpoints permitido."
else
  bad "Sem permissao para SageMaker (ListEndpoints)."
fi

# 5. Execution role do SageMaker
echo "[5/7] Execution role do SageMaker ('$SM_ROLE')"
if aws iam get-role --role-name "$SM_ROLE" >/dev/null 2>&1; then
  pass "Execution role '$SM_ROLE' existe."
  info "Garanta acesso ao bucket do lab (dados de treino + artefatos do modelo)."
elif aws iam list-roles --max-items 1 >/dev/null 2>&1; then
  info "Role nao existe, mas voce tem iam:ListRoles (provavel poder cria-la)."
else
  bad "Sem a execution role e sem permissao de IAM para cria-la."
fi

# 6. S3
echo "[6/7] Permissoes S3"
if aws s3 ls >/dev/null 2>&1; then
  pass "s3:ListAllMyBuckets permitido."
else
  bad "Sem permissao para listar buckets S3."
fi

# 7. Quotas de instancia de ML (ponto critico: foi o que travou turmas passadas)
echo "[7/7] Quotas de instancia de ML em $REGION"
QUOTAS="$(aws service-quotas list-service-quotas --service-code sagemaker \
  --region "$REGION" --query 'Quotas[].[QuotaName,Value,QuotaCode]' \
  --output text 2>/dev/null)"
PENDING="$(aws service-quotas list-requested-service-quota-change-history \
  --service-code sagemaker --region "$REGION" \
  --query "RequestedQuotas[?Status=='PENDING' || Status=='CASE_OPENED'].[QuotaName,DesiredValue]" \
  --output text 2>/dev/null)"

# quota_of "<nome exato da quota>" -> imprime o valor inteiro (vazio se nao achar)
quota_of() {
  printf '%s\n' "$QUOTAS" | awk -F'\t' -v n="$1" '$1==n {printf "%d", $2; exit}'
}
code_of() {
  printf '%s\n' "$QUOTAS" | awk -F'\t' -v n="$1" '$1==n {print $3; exit}'
}
pending_hint() {
  local p
  p="$(printf '%s\n' "$PENDING" | awk -F'\t' -v n="$1" '$1==n {printf "%d", $2; exit}')"
  if [ -n "$p" ]; then
    info "Ha pedido de aumento em andamento para '$1' (valor pedido: $p)."
  else
    info "Peca aumento: aws service-quotas request-service-quota-increase --service-code sagemaker --quota-code $(code_of "$1") --desired-value 2 --region $REGION"
  fi
}

# check_quota <obrigatorio|opcional> "<nome da quota>" "<descricao>"
check_quota() {
  local nivel="$1" nome="$2" desc="$3" v
  v="$(quota_of "$nome")"
  if [ -z "$v" ]; then
    warnf "Nao encontrei a quota '$nome'. Verifique em Service Quotas > SageMaker."
  elif [ "$v" -gt 0 ]; then
    pass "$desc: quota $v ($nome)."
  elif [ "$nivel" = "obrigatorio" ]; then
    bad "$desc: quota 0 ($nome). O lab NAO roda assim."
    pending_hint "$nome"
  else
    warnf "$desc: quota 0 ($nome). Esta parte do lab fica indisponivel."
    pending_hint "$nome"
  fi
}

if [ -z "$QUOTAS" ]; then
  bad "Nao consegui ler as quotas (servicequotas:ListServiceQuotas). Verifique manualmente no console."
else
  check_quota obrigatorio "$NOTEBOOK_TYPE for notebook instance usage" "Notebook ($NOTEBOOK_TYPE)"
  check_quota obrigatorio "$TRAIN_TYPE for training job usage"        "Training Job ($TRAIN_TYPE)"
  check_quota opcional    "$TRANSFORM_TYPE for transform job usage"   "Batch Transform ($TRANSFORM_TYPE)"

  # Deploy: basta Endpoint provisionado OU Serverless Inference
  EP="$(quota_of "$ENDPOINT_TYPE for endpoint usage")"
  SL="$(quota_of "Maximum number of serverless endpoints")"
  if [ "${EP:-0}" -gt 0 ] || [ "${SL:-0}" -gt 0 ]; then
    pass "Deploy: Endpoint $ENDPOINT_TYPE quota ${EP:-?}; Serverless Endpoints quota ${SL:-?}."
  else
    bad "Deploy: sem quota de Endpoint ($ENDPOINT_TYPE) nem de Serverless Inference."
  fi
fi

echo
echo "== Resultado: $ok ok, $warn avisos, $fail com problema =="
if [ "$fail" -gt 0 ]; then
  echo "Resolva os itens marcados com ❌ antes da aula. Veja troubleshooting.md."
  echo "Quota de ML pode levar DIAS para ser aprovada: nao deixe para a vespera."
  exit 1
fi
echo "Ambiente pronto para o Lab C (PDN). LEMBRE-SE: apague o ENDPOINT ao terminar."
