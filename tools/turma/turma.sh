#!/usr/bin/env bash
#
# turma.sh - acesso efemero e barato dos alunos ao SageMaker da conta do instrutor
#
# Cria, para uma turma, usuarios IAM temporarios que so conseguem:
#   - usar o CloudShell (terminal no navegador, gratuito; nada a instalar);
#   - ler/gravar na SUA pasta de um bucket da turma;
#   - treinar e fazer Batch Transform em ml.m5.large, no maximo 15 min por job;
#   - fazer deploy SO em endpoint serverless (nao cobra parado);
#   - mexer apenas em recursos com nome iniciado pelo proprio usuario.
# Tudo expira sozinho na data de --expira (a politica nega apos essa data),
# mesmo que o instrutor esqueca de rodar 'limpar'.
#
# Uso:
#   tools/turma/turma.sh criar  --turma pdn-2026-2 --alunos 30 --expira 2026-12-15 [--email voce@x.com] [--orcamento 20]
#   tools/turma/turma.sh status --turma pdn-2026-2
#   tools/turma/turma.sh limpar --turma pdn-2026-2 [--sim]
#
# Requer: AWS CLI v2 com credencial de administrador da conta, python3.
#
set -uo pipefail

REGION="${REGION:-us-east-1}"
CMD="${1:-}"; shift || true
TURMA=""; ALUNOS=""; EXPIRA=""; EMAIL=""; ORCAMENTO="20"; SIM=0
while [ $# -gt 0 ]; do
  case "$1" in
    --turma) TURMA="$2"; shift 2;;
    --alunos) ALUNOS="$2"; shift 2;;
    --expira) EXPIRA="$2"; shift 2;;
    --email) EMAIL="$2"; shift 2;;
    --orcamento) ORCAMENTO="$2"; shift 2;;
    --sim) SIM=1; shift;;
    *) echo "opcao desconhecida: $1" >&2; exit 2;;
  esac
done

die() { echo "ERRO: $*" >&2; exit 1; }
log() { printf '  %s\n' "$*"; }

# ---- validacoes comuns ------------------------------------------------------
[ -n "$CMD" ] || die "informe um comando: criar | status | limpar"
[ -n "$TURMA" ] || die "--turma obrigatorio (ex.: pdn-2026-2)"
# minusculas: o SageMaker grava ARNs em minusculas e a politica compara o prefixo
printf '%s' "$TURMA" | grep -Eq '^[a-z0-9][a-z0-9-]{1,19}$' \
  || die "--turma: use 2-20 caracteres [a-z0-9-] (ex.: pdn-2026-2)"
command -v aws >/dev/null || die "AWS CLI nao encontrada"
command -v python3 >/dev/null || die "python3 nao encontrado"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)" \
  || die "sem credencial AWS valida"

GROUP="${TURMA}-alunos"
ROLE="${TURMA}-SageMakerRole"
BUCKET="${TURMA}-sagemaker-${ACCOUNT_ID}"
BUDGET="${TURMA}-sagemaker"
OUT="$HOME/turma-${TURMA}-credenciais.csv"

usuarios() {
  aws iam get-group --group-name "$GROUP" --query 'Users[].UserName' --output text 2>/dev/null | tr '\t' '\n' | grep -v '^$'
}

# ---- politicas ----------------------------------------------------------------
politica_aluno() {
  # ${aws:username} e variavel de politica do IAM: NAO e expandida pelo shell
  python3 - "$REGION" "$ACCOUNT_ID" "$BUCKET" "$ROLE" "$EXPIRA" <<'PY'
import json,sys
reg,acc,bucket,role,exp=sys.argv[1:]
u='${aws:username}'
sm=lambda t:f'arn:aws:sagemaker:{reg}:{acc}:{t}/{u}-*'
ate={"DateLessThan":{"aws:CurrentTime":f"{exp}T23:59:59Z"}}
doc={"Version":"2012-10-17","Statement":[
 {"Sid":"CloudShellELeitura","Effect":"Allow","Resource":"*","Condition":ate,
  "Action":["cloudshell:*","sagemaker:List*","sagemaker:Describe*",
            "logs:DescribeLogStreams","logs:GetLogEvents","logs:FilterLogEvents"]},
 {"Sid":"SoOsProprios","Effect":"Allow","Condition":ate,
  "Action":["sagemaker:CreateTrainingJob","sagemaker:StopTrainingJob",
            "sagemaker:CreateTransformJob","sagemaker:StopTransformJob",
            "sagemaker:CreateModel","sagemaker:DeleteModel",
            "sagemaker:CreateEndpointConfig","sagemaker:DeleteEndpointConfig",
            "sagemaker:CreateEndpoint","sagemaker:DeleteEndpoint","sagemaker:InvokeEndpoint"],
  "Resource":[sm('training-job'),sm('transform-job'),sm('model'),sm('endpoint-config'),sm('endpoint')]},
 {"Sid":"PassaSoARoleDaTurma","Effect":"Allow","Action":"iam:PassRole","Condition":
   {**ate,"StringEquals":{"iam:PassedToService":"sagemaker.amazonaws.com"}},
  "Resource":f"arn:aws:iam::{acc}:role/{role}"},
 {"Sid":"PastaPropria","Effect":"Allow","Condition":ate,
  "Action":["s3:GetObject","s3:PutObject","s3:DeleteObject"],
  "Resource":f"arn:aws:s3:::{bucket}/{u}/*"},
 {"Sid":"ListaPastaPropria","Effect":"Allow","Action":"s3:ListBucket",
  "Resource":f"arn:aws:s3:::{bucket}",
  "Condition":{**ate,"StringLike":{"s3:prefix":[f"{u}/*",f"{u}/",u]}}},
 # --- travas de custo (Deny vence qualquer Allow) ---
 {"Sid":"SoInstanciaPequena","Effect":"Deny",
  "Action":["sagemaker:CreateTrainingJob","sagemaker:CreateTransformJob"],"Resource":"*",
  "Condition":{"ForAnyValue:StringNotEquals":{"sagemaker:InstanceTypes":["ml.m5.large"]}}},
 {"Sid":"TreinoComTempoMaximo","Effect":"Deny","Action":"sagemaker:CreateTrainingJob","Resource":"*",
  "Condition":{"NumericGreaterThan":{"sagemaker:MaxRuntimeInSeconds":"900"}}},
 {"Sid":"TreinoSemTempoMaximo","Effect":"Deny","Action":"sagemaker:CreateTrainingJob","Resource":"*",
  "Condition":{"Null":{"sagemaker:MaxRuntimeInSeconds":"true"}}},
 {"Sid":"SoEndpointServerless","Effect":"Deny","Action":"sagemaker:CreateEndpointConfig","Resource":"*",
  "Condition":{"Null":{"sagemaker:ServerlessMaxConcurrency":"true"}}},
 {"Sid":"ServerlessPequeno","Effect":"Deny","Action":"sagemaker:CreateEndpointConfig","Resource":"*",
  "Condition":{"NumericGreaterThan":{"sagemaker:ServerlessMaxConcurrency":"1"}}},
 {"Sid":"ServerlessMemoriaPequena","Effect":"Deny","Action":"sagemaker:CreateEndpointConfig","Resource":"*",
  "Condition":{"NumericGreaterThan":{"sagemaker:ServerlessMemorySize":"2048"}}},
]}
print(json.dumps(doc,separators=(',',':')))
PY
}

politica_role() {
  python3 - "$BUCKET" <<'PY'
import json,sys
b=sys.argv[1]
print(json.dumps({"Version":"2012-10-17","Statement":[
 {"Effect":"Allow","Action":["s3:GetObject","s3:PutObject","s3:ListBucket"],
  "Resource":[f"arn:aws:s3:::{b}",f"arn:aws:s3:::{b}/*"]},
 {"Effect":"Allow","Action":["ecr:GetAuthorizationToken","ecr:BatchGetImage",
   "ecr:GetDownloadUrlForLayer","ecr:BatchCheckLayerAvailability"],"Resource":"*"},
 {"Effect":"Allow","Action":["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents",
   "logs:DescribeLogStreams","cloudwatch:PutMetricData"],"Resource":"*"}]},separators=(',',':')))
PY
}

senha() {
  python3 -c "
import secrets,string
a=string.ascii_letters+string.digits
s=''.join(secrets.choice(a) for _ in range(14))
print(s[:4]+'-'+s[4:9]+'-'+s[9:]+'#7a')"
}

# ---- criar --------------------------------------------------------------------
criar() {
  [ -n "$ALUNOS" ] || die "--alunos obrigatorio (quantidade, ex.: 30)"
  printf '%s' "$ALUNOS" | grep -Eq '^[0-9]+$' && [ "$ALUNOS" -ge 1 ] && [ "$ALUNOS" -le 99 ] \
    || die "--alunos: numero entre 1 e 99"
  [ -n "$EXPIRA" ] || die "--expira obrigatorio (AAAA-MM-DD, ultimo dia de acesso)"
  python3 -c "import datetime,sys;d=datetime.date.fromisoformat('$EXPIRA');sys.exit(0 if d>=datetime.date.today() else 1)" 2>/dev/null \
    || die "--expira invalido ou no passado: $EXPIRA"
  [ -e "$OUT" ] && die "$OUT ja existe (turma ja criada?). Rode 'limpar' antes ou use outro --turma."

  echo "== Criando turma '$TURMA' na conta $ACCOUNT_ID ($REGION), $ALUNOS alunos, acesso ate $EXPIRA"

  # quota: quantos alunos conseguem treinar / fazer batch AO MESMO TEMPO
  for q in "L-611FA074:treino" "L-236AE59F:batch transform"; do
    code="${q%%:*}"; nome="${q#*:}"
    v="$(aws service-quotas get-service-quota --service-code sagemaker --quota-code "$code" \
          --region "$REGION" --query 'Quota.Value' --output text 2>/dev/null | cut -d. -f1)"
    if [ -n "$v" ] && [ "$v" -lt "$ALUNOS" ]; then
      echo "  AVISO: quota de $nome em ml.m5.large = $v simultaneos (< $ALUNOS alunos)."
      echo "         Quem passar disso recebe ResourceLimitExceeded e tenta de novo em ~3 min."
      echo "         Para aumentar (gratis, leva horas/dias):"
      echo "         aws service-quotas request-service-quota-increase --service-code sagemaker --quota-code $code --desired-value $ALUNOS --region $REGION"
    fi
  done

  echo "[1/5] Bucket da turma: $BUCKET"
  if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
    if [ "$REGION" = us-east-1 ]; then aws s3api create-bucket --bucket "$BUCKET" >/dev/null
    else aws s3api create-bucket --bucket "$BUCKET" --create-bucket-configuration "LocationConstraint=$REGION" >/dev/null; fi
  fi
  aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  # rede de seguranca de custo: objetos somem sozinhos 30 dias depois
  aws s3api put-bucket-lifecycle-configuration --bucket "$BUCKET" --lifecycle-configuration \
    '{"Rules":[{"ID":"expira-30d","Status":"Enabled","Filter":{"Prefix":""},"Expiration":{"Days":30}}]}'
  log "ok (privado; objetos expiram em 30 dias)"

  echo "[2/5] Role de execucao do SageMaker: $ROLE"
  if ! aws iam get-role --role-name "$ROLE" >/dev/null 2>&1; then
    aws iam create-role --role-name "$ROLE" --tags "Key=turma,Value=$TURMA" \
      --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"sagemaker.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
  fi
  aws iam put-role-policy --role-name "$ROLE" --policy-name turma-sagemaker --policy-document "$(politica_role)"
  log "ok (so acessa o bucket da turma)"

  echo "[3/5] Grupo com a politica dos alunos: $GROUP"
  aws iam get-group --group-name "$GROUP" >/dev/null 2>&1 || aws iam create-group --group-name "$GROUP" >/dev/null
  aws iam put-group-policy --group-name "$GROUP" --policy-name acesso-turma --policy-document "$(politica_aluno)"
  log "ok (expira em $EXPIRA 23:59 UTC)"

  echo "[4/5] Usuarios"
  umask 077
  echo "usuario,senha,login_url" > "$OUT"
  i=1
  while [ "$i" -le "$ALUNOS" ]; do
    U="$(printf '%s-a%02d' "$TURMA" "$i")"
    P="$(senha)"
    aws iam create-user --user-name "$U" --tags "Key=turma,Value=$TURMA" "Key=expira,Value=$EXPIRA" >/dev/null \
      || die "falha ao criar $U"
    aws iam create-login-profile --user-name "$U" --password "$P" --no-password-reset-required >/dev/null \
      || die "falha ao definir senha de $U (politica de senha da conta?)"
    aws iam add-user-to-group --user-name "$U" --group-name "$GROUP"
    echo "$U,$P,https://${ACCOUNT_ID}.signin.aws.amazon.com/console" >> "$OUT"
    i=$((i+1))
  done
  log "ok: $ALUNOS usuarios. Credenciais em $OUT (so voce le; NAO commite)"

  echo "[5/5] Alerta de orcamento"
  if [ -n "$EMAIL" ]; then
    aws budgets create-budget --account-id "$ACCOUNT_ID" \
      --budget "{\"BudgetName\":\"$BUDGET\",\"BudgetLimit\":{\"Amount\":\"$ORCAMENTO\",\"Unit\":\"USD\"},\"TimeUnit\":\"MONTHLY\",\"BudgetType\":\"COST\",\"CostFilters\":{\"Service\":[\"Amazon SageMaker\"]}}" \
      --notifications-with-subscribers "[{\"Notification\":{\"NotificationType\":\"ACTUAL\",\"ComparisonOperator\":\"GREATER_THAN\",\"Threshold\":50,\"ThresholdType\":\"PERCENTAGE\"},\"Subscribers\":[{\"SubscriptionType\":\"EMAIL\",\"Address\":\"$EMAIL\"}]},{\"Notification\":{\"NotificationType\":\"ACTUAL\",\"ComparisonOperator\":\"GREATER_THAN\",\"Threshold\":100,\"ThresholdType\":\"PERCENTAGE\"},\"Subscribers\":[{\"SubscriptionType\":\"EMAIL\",\"Address\":\"$EMAIL\"}]}]" \
      && log "ok: e-mail para $EMAIL ao passar de 50% e 100% de US\$ $ORCAMENTO/mes em SageMaker"
  else
    log "pulado (use --email para receber alerta de gasto)"
  fi

  cat <<EOF

== Pronto. Passe aos alunos (slide/Classroom):

  1. Entre em https://${ACCOUNT_ID}.signin.aws.amazon.com/console
     com o usuario e a senha que voce recebeu.
  2. Depois do login, abra (ja cai no CloudShell, na regiao certa):
     https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1
     (o console abre por padrao em us-east-2; o lab e em us-east-1)
  3. No CloudShell, cole:

       export TURMA_BUCKET="$BUCKET"
       export SM_ROLE="$ROLE"

     e siga o passo-a-passo do Lab C a partir de "Modo turma".

  O acesso termina sozinho em $EXPIRA. Depois da aula: tools/turma/turma.sh limpar --turma $TURMA
EOF
}

# ---- status -------------------------------------------------------------------
status() {
  echo "== Turma '$TURMA' (conta $ACCOUNT_ID, $REGION)"
  N="$(usuarios | wc -l | tr -d ' ')"
  echo "usuarios: $N"
  echo "endpoints ativos da turma:"
  aws sagemaker list-endpoints --name-contains "$TURMA-a" --query 'Endpoints[].[EndpointName,EndpointStatus]' --output text | sed 's/^/  /'
  echo "jobs de treino rodando:"
  aws sagemaker list-training-jobs --name-contains "$TURMA-a" --status-equals InProgress --query 'TrainingJobSummaries[].TrainingJobName' --output text | tr '\t' '\n' | sed 's/^/  /'
  echo "batch transform rodando:"
  aws sagemaker list-transform-jobs --name-contains "$TURMA-a" --status-equals InProgress --query 'TransformJobSummaries[].TransformJobName' --output text | tr '\t' '\n' | sed 's/^/  /'
  echo "treinos concluidos por aluno:"
  aws sagemaker list-training-jobs --name-contains "$TURMA-a" --status-equals Completed --max-results 100 --query 'TrainingJobSummaries[].TrainingJobName' --output text \
    | tr '\t' '\n' | grep -v '^$' | sed -E "s/^(${TURMA}-a[0-9]+)-.*/\1/" | sort | uniq -c | sed 's/^/  /'
}

# ---- limpar -------------------------------------------------------------------
limpar() {
  echo "== Limpar turma '$TURMA' na conta $ACCOUNT_ID ($REGION)"
  echo "   Apaga: endpoints/configs/modelos '$TURMA-a*', para jobs em andamento,"
  echo "   usuarios do grupo $GROUP, o grupo, a role $ROLE, o bucket $BUCKET e o orcamento."
  if [ "$SIM" != 1 ]; then
    printf 'Confirmar? digite o nome da turma: '; read -r R
    [ "$R" = "$TURMA" ] || die "cancelado"
  fi
  P="$TURMA-a"
  for e in $(aws sagemaker list-endpoints --name-contains "$P" --query 'Endpoints[].EndpointName' --output text); do
    aws sagemaker delete-endpoint --endpoint-name "$e" && log "endpoint $e"; done
  for c in $(aws sagemaker list-endpoint-configs --name-contains "$P" --query 'EndpointConfigs[].EndpointConfigName' --output text); do
    aws sagemaker delete-endpoint-config --endpoint-config-name "$c" && log "endpoint-config $c"; done
  for m in $(aws sagemaker list-models --name-contains "$P" --query 'Models[].ModelName' --output text); do
    aws sagemaker delete-model --model-name "$m" && log "modelo $m"; done
  for j in $(aws sagemaker list-training-jobs --name-contains "$P" --status-equals InProgress --query 'TrainingJobSummaries[].TrainingJobName' --output text); do
    aws sagemaker stop-training-job --training-job-name "$j" && log "treino parado $j"; done
  for j in $(aws sagemaker list-transform-jobs --name-contains "$P" --status-equals InProgress --query 'TransformJobSummaries[].TransformJobName' --output text); do
    aws sagemaker stop-transform-job --transform-job-name "$j" && log "batch parado $j"; done

  for U in $(usuarios); do
    aws iam delete-login-profile --user-name "$U" 2>/dev/null
    for k in $(aws iam list-access-keys --user-name "$U" --query 'AccessKeyMetadata[].AccessKeyId' --output text); do
      aws iam delete-access-key --user-name "$U" --access-key-id "$k"; done
    aws iam remove-user-from-group --user-name "$U" --group-name "$GROUP"
    aws iam delete-user --user-name "$U" && log "usuario $U"
  done
  aws iam delete-group-policy --group-name "$GROUP" --policy-name acesso-turma 2>/dev/null
  aws iam delete-group --group-name "$GROUP" 2>/dev/null && log "grupo $GROUP"
  aws iam delete-role-policy --role-name "$ROLE" --policy-name turma-sagemaker 2>/dev/null
  aws iam delete-role --role-name "$ROLE" 2>/dev/null && log "role $ROLE"
  aws s3 rb "s3://$BUCKET" --force >/dev/null 2>&1 && log "bucket $BUCKET"
  aws budgets delete-budget --account-id "$ACCOUNT_ID" --budget-name "$BUDGET" >/dev/null 2>&1 && log "orcamento $BUDGET"
  [ -f "$OUT" ] && rm -f "$OUT" && log "arquivo de credenciais $OUT"
  echo "== Turma '$TURMA' removida."
}

case "$CMD" in
  criar) criar;;
  status) status;;
  limpar) limpar;;
  *) die "comando invalido: $CMD (use criar | status | limpar)";;
esac
