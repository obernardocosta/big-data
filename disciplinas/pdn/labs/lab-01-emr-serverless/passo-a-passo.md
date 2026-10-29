# Lab 01 (PDN) — Passo a passo

> Rode o `dry-run.sh` deste lab antes da aula. Ele checa credencial, região,
> usuário IAM, a RuntimeRole e as permissões de EMR Serverless/S3 — read-only,
> sem criar Application nem submeter job (o job é o que gera custo).

> **Custo:** o passo 4 **submete o job** e aí há cobrança por vCPU/GB-hora.
> Jobs pequenos custam centavos. Faça a limpeza ao final.

Base oficial (siga os exemplos): https://github.com/aws-samples/emr-serverless-samples

```bash
export BUCKET="pdn-lab01-$(whoami)-$RANDOM"
export REGION="us-east-1"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export RUNTIME_ROLE="EMRServerlessJobRole"
```

## 1. Pré-requisitos: bucket e dados/script

**Porquê:** o EMR Serverless lê entrada e script do S3 e grava a saída no S3 — o
armazenamento é desacoplado da computação.

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

cat > job.py <<'PY'
import sys
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("pdn-emrs").getOrCreate()
df = spark.range(1, 1000).withColumnRenamed("id", "n")
df.groupBy((df.n % 3).alias("resto")).count().write.mode("overwrite").parquet(sys.argv[1])
spark.stop()
PY
aws s3 cp job.py "s3://$BUCKET/scripts/job.py"
```

## 2. Criar a RuntimeRole (role POR JOB)

**Porquê:** no EMR Serverless a permissão é do **job**, não do cluster. Esta role
é assumida pelo serviço para rodar **este** job — menor privilégio.

```bash
cat > trust-emrs.json <<'JSON'
{ "Version": "2012-10-17",
  "Statement": [{ "Effect": "Allow",
    "Principal": {"Service": "emr-serverless.amazonaws.com"},
    "Action": "sts:AssumeRole" }] }
JSON

aws iam create-role --role-name "$RUNTIME_ROLE" \
  --assume-role-policy-document file://trust-emrs.json
aws iam attach-role-policy --role-name "$RUNTIME_ROLE" \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

## 3. Criar a Application (ainda sem custo relevante)

**Porquê:** a Application é o ambiente Spark. Criá-la não sobe capacidade; a
capacidade só é alocada quando um job roda.

```bash
APP_ID=$(aws emr-serverless create-application \
  --name "lab-pdn-emrs" --type "SPARK" \
  --release-label "emr-7.1.0" \
  --region "$REGION" --query 'applicationId' --output text)
echo "Application: $APP_ID"
```

## 4. Submeter o job PySpark (AQUI começa o custo)

**Porquê:** este é o ponto do lab — Spark serverless, cobrança só pelo tempo do job.

```bash
RUN_ID=$(aws emr-serverless start-job-run \
  --application-id "$APP_ID" \
  --execution-role-arn "arn:aws:iam::$ACCOUNT_ID:role/$RUNTIME_ROLE" \
  --job-driver "{\"sparkSubmit\":{\"entryPoint\":\"s3://$BUCKET/scripts/job.py\",\"entryPointArguments\":[\"s3://$BUCKET/out/\"]}}" \
  --region "$REGION" --query 'jobRunId' --output text)

# acompanhe o estado (PENDING -> RUNNING -> SUCCESS)
aws emr-serverless get-job-run --application-id "$APP_ID" --job-run-id "$RUN_ID" \
  --query 'jobRun.state'
```

## 5. Conferir a saída no S3

```bash
aws s3 ls "s3://$BUCKET/out/" --recursive
```

## 6. (Obrigatório 2) Dependências Python

**Porquê:** jobs reais usam libs que não vêm no runtime. O padrão é empacotar um
**virtualenv** (`--archives` com `venv-pack`) ou usar `--py-files`.

- Siga o exemplo **Python Dependencies** do repositório oficial
  (`emr-serverless-samples`): crie o pacote de dependências, suba no S3 e
  referencie no `sparkSubmit` via `--archives`/`spark.archives`.

## 7. (Extra) Hive query no EMR Serverless

**Porquê:** mostra que a Application também roda **Hive**, não só Spark. Crie uma
Application do tipo `HIVE` e submeta uma query. Veja o exemplo correspondente no
repositório oficial.

## Limpeza

Veja a seção "Limpeza" do `README.md`.
