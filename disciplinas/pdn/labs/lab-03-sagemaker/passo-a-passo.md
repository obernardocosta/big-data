# Lab C (PDN) — Passo a passo

> Rode o `dry-run.sh` deste lab antes da aula. Ele checa credencial, região,
> usuário IAM, a execution role do SageMaker e as permissões de SageMaker/S3 —
> read-only, sem treinar nem criar endpoint (o que gera custo).

> **Custo:** Training Job cobra por segundo de instância; **o Endpoint cobra
> enquanto estiver no ar**. Use instâncias pequenas e **apague o Endpoint** ao
> final.

O lab segue o notebook disponibilizado pela turma. Os comandos abaixo mostram o
fluxo conceitual (via SDK/CLI) para quem quiser reproduzir fora do notebook.

```bash
export BUCKET="pdn-lab03-$(whoami)-$RANDOM"
export REGION="us-east-1"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export SM_ROLE="SageMakerExecutionRole"
```

## 1. Pré-requisitos: bucket e execution role

**Porquê:** o SageMaker usa uma **execution role** para ler dados e gravar
artefatos de modelo no S3. É ela que o Training Job e o Endpoint assumem.

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

cat > trust-sm.json <<'JSON'
{ "Version": "2012-10-17",
  "Statement": [{ "Effect": "Allow",
    "Principal": {"Service": "sagemaker.amazonaws.com"},
    "Action": "sts:AssumeRole" }] }
JSON
aws iam create-role --role-name "$SM_ROLE" \
  --assume-role-policy-document file://trust-sm.json
aws iam attach-role-policy --role-name "$SM_ROLE" \
  --policy-arn arn:aws:iam::aws:policy/AmazonSageMakerFullAccess
aws iam attach-role-policy --role-name "$SM_ROLE" \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# role recem-criada leva alguns segundos para propagar no IAM; sem esta pausa
# o primeiro Training Job falha com "The AWS Access Key Id you provided does
# not exist in our records" (visto no teste real)
sleep 15
```

## 2. Manipulação dos dados (Notebook)

**Porquê:** primeira etapa do ML (Data Wrangling). No Notebook gerenciado, você
prepara os dados e sobe o dataset de treino para o S3.

- Abra o **notebook do lab** (link nas instruções da turma) e execute as células
  de preparação, que gravam o dataset em `s3://$BUCKET/input/`.

## 3. Treinamento do modelo (Training Job)

**Porquê:** o SageMaker provisiona a instância de treino **sob demanda**, roda o
algoritmo e salva o artefato do modelo no S3 — sem você gerenciar servidor/GPU.

- No notebook, use o Estimator do SDK (`sagemaker.estimator.Estimator` ou um
  algoritmo built-in) apontando entrada para `s3://$BUCKET/input/` e saída para
  `s3://$BUCKET/model/`. O `fit()` dispara o Training Job.
- Acompanhe o estado:

```bash
aws sagemaker list-training-jobs --max-results 5 \
  --query 'TrainingJobSummaries[].{Nome:TrainingJobName,Estado:TrainingJobStatus}'
```

## 4. Deploy do modelo

**Porquê:** servir o modelo. Duas opções (Aula 2):

- **Endpoint (tempo real)** — `estimator.deploy(...)` cria um endpoint que
  responde requisição a requisição. **Cobra enquanto existir.**
- **Batch Transform** — inferência em lote sobre um dataset, sem endpoint
  permanente (melhor para custo quando não precisa de tempo real).

## 5. Testar a inferência

```bash
# exemplo conceitual (via SDK no notebook): predictor.predict(amostra)
aws sagemaker list-endpoints \
  --query 'Endpoints[].{Nome:EndpointName,Estado:EndpointStatus}'
```

## 5b. Caminho reproduzível via CLI (testado em 2026-11-08)

**Porquê:** o mesmo ciclo dados → Training Job → deploy, sem depender do
notebook da turma. Útil para o instrutor validar a conta na véspera e para quem
quiser refazer em casa. Custo medido: centavos (treino de ~2 min em
`ml.m5.large`, endpoint **serverless**, que não cobra parado).

```bash
# dataset: o mandante venceu (1/0)? features = media de gols pro/contra de
# cada time nos jogos ANTERIORES (dados reais 2024/25, openfootball)
curl -s https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json \
  | python3 -c "
import json,sys,csv,collections
ms=sorted(json.load(sys.stdin)['matches'],key=lambda m:m['date'])
gf=collections.defaultdict(list); ga=collections.defaultdict(list)
avg=lambda l: sum(l)/len(l) if l else 1.4
rows=[]
for m in ms:
    ft=(m.get('score') or {}).get('ft')
    if not ft: continue
    h,a=m['team1'],m['team2']
    rows.append([1 if ft[0]>ft[1] else 0, round(avg(gf[h]),3), round(avg(ga[h]),3), round(avg(gf[a]),3), round(avg(ga[a]),3)])
    gf[h].append(ft[0]); ga[h].append(ft[1]); gf[a].append(ft[1]); ga[a].append(ft[0])
csv.writer(open('train.csv','w')).writerows(rows[:300])            # rotulo na 1a coluna
csv.writer(open('test.csv','w')).writerows([r[1:] for r in rows[300:]])
"
aws s3 cp train.csv "s3://$BUCKET/input/train/train.csv"
aws s3 cp test.csv  "s3://$BUCKET/input/test/test.csv"

# Training Job com o XGBoost nativo do SageMaker
export IMAGE="683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1"
export JOB="pdn-labc-$(date +%H%M%S)"
aws sagemaker create-training-job --training-job-name "$JOB" \
  --algorithm-specification TrainingImage=$IMAGE,TrainingInputMode=File \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/$SM_ROLE" \
  --input-data-config "[{\"ChannelName\":\"train\",\"ContentType\":\"text/csv\",\"DataSource\":{\"S3DataSource\":{\"S3DataType\":\"S3Prefix\",\"S3Uri\":\"s3://$BUCKET/input/train/\",\"S3DataDistributionType\":\"FullyReplicated\"}}}]" \
  --output-data-config "S3OutputPath=s3://$BUCKET/model/" \
  --resource-config InstanceType=ml.m5.large,InstanceCount=1,VolumeSizeInGB=5 \
  --stopping-condition MaxRuntimeInSeconds=900 \
  --hyper-parameters objective=binary:logistic,num_round=50,max_depth=3
```

**Espere o treino terminar** (~3 min: `Starting → Downloading → Training →
Uploading → Completed`). Repita até ver `Completed`:

```bash
aws sagemaker describe-training-job --training-job-name "$JOB" \
  --query '[TrainingJobStatus,SecondaryStatus]'
```

Com o treino concluído, registre o modelo e suba o endpoint:

```bash
# Modelo + endpoint SERVERLESS (cobra por requisicao, nao por hora)
ART=$(aws sagemaker describe-training-job --training-job-name "$JOB" \
  --query ModelArtifacts.S3ModelArtifacts --output text)
aws sagemaker create-model --model-name "$JOB-model" \
  --execution-role-arn "arn:aws:iam::${ACCOUNT_ID}:role/$SM_ROLE" \
  --primary-container "Image=$IMAGE,ModelDataUrl=$ART"
aws sagemaker create-endpoint-config --endpoint-config-name "$JOB-cfg" \
  --production-variants "VariantName=v1,ModelName=$JOB-model,ServerlessConfig={MemorySizeInMB=2048,MaxConcurrency=1}"
aws sagemaker create-endpoint --endpoint-name "$JOB-ep" --endpoint-config-name "$JOB-cfg"
```

**Espere o endpoint** ficar `InService` (~3 min; repita):

```bash
aws sagemaker describe-endpoint --endpoint-name "$JOB-ep" --query EndpointStatus
```

```bash
# Predicao em tempo real: probabilidade de vitoria do mandante
head -1 test.csv > amostra.csv
aws sagemaker-runtime invoke-endpoint --endpoint-name "$JOB-ep" \
  --content-type text/csv --body fileb://amostra.csv pred.json && cat pred.json

# (opcional) Batch Transform: as 80 predicoes de uma vez, sem endpoint
aws sagemaker create-transform-job --transform-job-name "$JOB-batch" \
  --model-name "$JOB-model" \
  --transform-input "DataSource={S3DataSource={S3DataType=S3Prefix,S3Uri=s3://$BUCKET/input/test/}},ContentType=text/csv,SplitType=Line" \
  --transform-output "S3OutputPath=s3://$BUCKET/batch-out/" \
  --transform-resources InstanceType=ml.m5.large,InstanceCount=1
```

> **Para discutir com a turma:** com só essas 4 features o modelo acerta ~57%,
> o mesmo que "chutar sempre a classe mais comum". O lab prova a
> **infraestrutura** (treinar, servir, escalar a zero); melhorar o modelo
> (mais features, mais temporadas) é o exercício seguinte.

Limpeza deste caminho: `delete-endpoint --endpoint-name "$JOB-ep"`,
`delete-endpoint-config --endpoint-config-name "$JOB-cfg"` e
`delete-model --model-name "$JOB-model"`, mais o bucket (passo 6).

## 6. LIMPEZA (faça antes de sair!)

**Porquê:** o **Endpoint** é o maior risco de custo do curso — ele cobra parado.

```bash
aws sagemaker delete-endpoint        --endpoint-name <ENDPOINT>
aws sagemaker delete-endpoint-config --endpoint-config-name <CONFIG>
aws sagemaker delete-model           --model-name <MODELO>
aws s3 rm "s3://$BUCKET/" --recursive
```

Veja também a seção "Limpeza" do `README.md`.
