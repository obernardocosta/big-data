#!/usr/bin/env bash
#
# dry-run REFORÇADO do Lab 06 - Amazon EMR workshop
#
# Este lab TEM custo e historicamente falhou por indisponibilidade de
# instancias na regiao. Este dry-run valida o ambiente SEM subir cluster
# (somente chamadas read-only), com atencao a CAPACIDADE/QUOTA de EC2.
# Rode isto na VESPERA da aula.
#
# Uso:
#   ./dry-run.sh
#   REGION=us-east-2 KEYNAME=minha-chave INSTANCE_TYPE=m5.xlarge ./dry-run.sh
#
set -uo pipefail

REGION="${REGION:-us-east-1}"
KEYNAME="${KEYNAME:-}"
INSTANCE_TYPE="${INSTANCE_TYPE:-m5.xlarge}"
ok=0
fail=0
warn=0

pass() { printf '  \033[32m✅ %s\033[0m\n' "$1"; ok=$((ok+1)); }
bad()  { printf '  \033[31m❌ %s\033[0m\n' "$1"; fail=$((fail+1)); }
warnf(){ printf '  \033[33m⚠️  %s\033[0m\n' "$1"; warn=$((warn+1)); }
info() { printf '  \033[36mℹ️  %s\033[0m\n' "$1"; }

echo "== Dry-run REFORÇADO Lab 06 (EMR) | regiao: $REGION | tipo: $INSTANCE_TYPE =="
echo "   (NAO sobe cluster; apenas verifica se o ambiente aguenta subir)"

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

# 3. Usuario IAM (OBRIGATORIO: root nao conecta no EMR Notebooks)
echo "[3/8] Usuario IAM (OBRIGATORIO - root nao conecta no EMR Notebooks)"
if [ -n "${ARN:-}" ]; then
  if printf '%s' "$ARN" | grep -q ':root'; then
    bad "Voce esta como ROOT. O EMR Notebooks exige usuario IAM."
  else
    pass "Usuario IAM (ok)."
  fi
else
  info "Pulado (sem credencial)."
fi

# 4. Regiao configurada
echo "[4/8] Regiao"
CUR_REGION="$(aws configure get region 2>/dev/null)"
if [ "$CUR_REGION" = "$REGION" ]; then
  pass "Regiao configurada = $REGION"
elif [ -n "$CUR_REGION" ]; then
  warnf "Regiao configurada ($CUR_REGION) difere do alvo ($REGION)."
else
  info "Nenhuma regiao default; usando --region nas chamadas."
fi

# 5. Roles de servico do EMR
echo "[5/8] Roles de servico do EMR"
if aws iam get-role --role-name EMR_DefaultRole >/dev/null 2>&1 \
   && aws iam get-role --role-name EMR_EC2_DefaultRole >/dev/null 2>&1; then
  pass "EMR_DefaultRole e EMR_EC2_DefaultRole existem."
else
  warnf "Roles padrao ausentes. Crie com 'aws emr create-default-roles' (sem custo)."
fi

# 6. Permissao de EMR (read-only)
echo "[6/8] Permissao EMR (read-only)"
if aws emr list-clusters --region "$REGION" >/dev/null 2>&1; then
  pass "elasticmapreduce:ListClusters permitido."
else
  bad "Sem permissao para EMR (ListClusters)."
fi

# 7. CAPACIDADE/QUOTA de EC2 na regiao (a causa da falha historica)
echo "[7/8] Capacidade/quota de EC2 na regiao (ponto critico)"
# 7a. o tipo de instancia e oferecido nesta regiao?
OFFERED="$(aws ec2 describe-instance-type-offerings \
  --location-type region --region "$REGION" \
  --filters "Name=instance-type,Values=$INSTANCE_TYPE" \
  --query 'InstanceTypeOfferings[0].InstanceType' --output text 2>/dev/null)"
if [ "$OFFERED" = "$INSTANCE_TYPE" ]; then
  pass "Tipo $INSTANCE_TYPE e oferecido em $REGION."
else
  bad "Tipo $INSTANCE_TYPE NAO parece oferecido em $REGION. Troque de tipo/regiao."
fi
# 7b. quota de vCPUs On-Demand (L-1216C47A) > 0?
QUOTA="$(aws service-quotas get-service-quota \
  --service-code ec2 --quota-code L-1216C47A --region "$REGION" \
  --query 'Quota.Value' --output text 2>/dev/null)"
if [ -n "$QUOTA" ] && [ "$QUOTA" != "None" ]; then
  pass "Quota de vCPUs On-Demand (Standard) em $REGION: $QUOTA."
else
  warnf "Nao consegui ler a quota de vCPUs (Service Quotas). Verifique manualmente."
fi

# 8. Par de chaves EC2 (para SSH, opcional mas recomendado)
echo "[8/8] Par de chaves EC2 (para SSH)"
if [ -z "$KEYNAME" ]; then
  info "KEYNAME nao informado. SSH e opcional; defina KEYNAME=... para checar."
elif aws ec2 describe-key-pairs --key-names "$KEYNAME" --region "$REGION" >/dev/null 2>&1; then
  pass "Par de chaves '$KEYNAME' existe em $REGION."
else
  warnf "Par de chaves '$KEYNAME' nao encontrado em $REGION (so afeta o SSH)."
fi

echo
echo "== Resultado: $ok ok, $warn avisos, $fail com problema =="
if [ "$fail" -gt 0 ]; then
  echo "Ha itens ❌. Resolva ANTES da aula ou use o plano B. Veja troubleshooting.md."
  exit 1
fi
if [ "$warn" -gt 0 ]; then
  echo "Ambiente provavelmente OK, mas revise os avisos ⚠️ (capacidade/roles/chave)."
fi
echo "Lembre-se: subir o cluster gera custo (~US\$ 1). Nao esqueca a limpeza."
