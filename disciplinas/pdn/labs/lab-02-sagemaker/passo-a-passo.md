# Lab 02 (PDN) — Passo a passo

> Rode o `dry-run.sh` deste lab antes da aula. Ele checa credencial, região,
> usuário IAM, a execution role do SageMaker e as permissões de SageMaker/S3 —
> read-only, sem treinar nem criar endpoint (o que gera custo).

> **Custo:** Training Job cobra por segundo de instância; **o Endpoint cobra
> enquanto estiver no ar**. Use instâncias pequenas e **apague o Endpoint** ao
> final.

O lab segue o notebook disponibilizado pela turma. Os comandos abaixo mostram o
fluxo conceitual (via SDK/CLI) para quem quiser reproduzir fora do notebook.

```bash
export BUCKET="pdn-lab02-$(whoami)-$RANDOM"
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

## 6. LIMPEZA (faça antes de sair!)

**Porquê:** o **Endpoint** é o maior risco de custo do curso — ele cobra parado.

```bash
aws sagemaker delete-endpoint        --endpoint-name <ENDPOINT>
aws sagemaker delete-endpoint-config --endpoint-config-name <CONFIG>
aws sagemaker delete-model           --model-name <MODELO>
aws s3 rm "s3://$BUCKET/" --recursive
```

Veja também a seção "Limpeza" do `README.md`.
