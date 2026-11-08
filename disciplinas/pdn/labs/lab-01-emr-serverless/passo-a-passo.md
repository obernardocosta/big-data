# PDN Lab 01 (Lab A) — Passo a passo

> **Como usar este roteiro**
>
> 1. Assista à **demo ao vivo** do instrutor (ele faz os passos 3 a 5 uma vez).
> 2. Repita você mesmo **no console da AWS**, seguindo as instruções de cada passo.
> 3. Travou ou está sem tempo? Cada passo tem um bloco **"Prefere o terminal?"**
>    (recolhido) com o mesmo passo em **AWS CLI**. Clique para abrir.

> **Custo:** o passo 4 **submete o job** e aí há cobrança por vCPU/GB-hora.
> Jobs pequenos custam centavos. Faça a limpeza ao final.

**Console da AWS:** <https://console.aws.amazon.com/> · região **N. Virginia
(`us-east-1`)**, confira no canto superior direito.

Base oficial (siga os exemplos): [aws-samples/emr-serverless-samples](https://github.com/aws-samples/emr-serverless-samples)

Se for usar o terminal ou o [AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1),
defina antes as variáveis (anote o nome do bucket: ele é único na AWS e você vai
usá-lo nos passos seguintes):

```bash
export BUCKET="pdn-lab01-$(whoami)-$RANDOM"
export REGION="us-east-1"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export RUNTIME_ROLE="EMRServerlessJobRole"
```

## 1. Pré-requisitos: bucket, dados reais e script

**Porquê:** o EMR Serverless lê entrada e script do S3 e grava a saída no S3 — o
armazenamento é desacoplado da computação. Os dados vêm de uma **fonte pública ([openfootball](https://github.com/openfootball/football.json))**, copiada no nosso [repo data](https://github.com/obernardocosta/data/tree/main/football) para o lab não depender de terceiros.

Este passo é **preparação**, não conceito do lab: baixar o JSON, escrever o
`job.py` e enviar tudo ao S3 não tem um equivalente simples no console. Por isso
aqui o **script é o caminho principal**. Rode no terminal ou no
[AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1)
(terminal no navegador, já com a AWS CLI e o Python):

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

# baixa jogos reais da Premier League 2024/25 (dominio publico, sem chave)
curl -s -o jogos.json \
  https://raw.githubusercontent.com/obernardocosta/data/main/football/premier-league/2024-25/en.1.json
aws s3 cp jogos.json "s3://$BUCKET/raw/jogos.json"

cat > job.py <<'PY'
import sys
from pyspark.sql import SparkSession, functions as F

spark = SparkSession.builder.appName("pdn-emrs-futebol").getOrCreate()

# o JSON (openfootball) tem {"name":..., "matches":[...]}; multiLine=True
df = spark.read.option("multiLine", True).json(sys.argv[1]).selectExpr("explode(matches) as m")
jogos = df.select(
    F.col("m.team1").alias("mandante"),
    F.col("m.team2").alias("visitante"),
    F.col("m.score.ft")[0].alias("gols_mandante"),
    F.col("m.score.ft")[1].alias("gols_visitante"),
)

# gols marcados em casa por time (agregacao simples de exemplo)
gols_casa = (jogos.groupBy("mandante")
             .agg(F.sum("gols_mandante").alias("gols_em_casa"))
             .orderBy(F.desc("gols_em_casa")))

gols_casa.write.mode("overwrite").option("compression", "gzip").parquet(sys.argv[2])
PY
aws s3 cp job.py "s3://$BUCKET/scripts/job.py"
```

**Como saber que deu certo:** no [Amazon S3](https://console.aws.amazon.com/s3/),
abra o seu bucket e veja `raw/jogos.json` e `scripts/job.py`.

## 2. Criar a RuntimeRole (role POR JOB)

**Porquê:** no EMR Serverless a permissão é do **job**, não do cluster. Esta role
é assumida pelo serviço para rodar **este** job — menor privilégio.

**No console:**

1. Abra o [IAM](https://console.aws.amazon.com/iam/) e vá em **Roles > Create role**.
2. **Trusted entity type:** **AWS service**. Em **Use case**, escolha
   **EMR Serverless** (ou, se não aparecer, **Custom trust policy** com o
   principal `emr-serverless.amazonaws.com`, como no script abaixo). Avance.
3. Em **Add permissions**, busque e marque `AmazonS3FullAccess`. Avance.
   (No lab é prático; em produção você restringiria ao bucket.)
4. **Role name:** `EMRServerlessJobRole`. Clique em **Create role**.

**Como saber que deu certo:** a role `EMRServerlessJobRole` aparece em **Roles**,
com a policy `AmazonS3FullAccess` e a relação de confiança com
`emr-serverless.amazonaws.com`.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

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

</details>

## 3. Criar a Application (ainda sem custo relevante)

**Porquê:** a Application é o ambiente Spark. Criá-la não sobe capacidade; a
capacidade só é alocada quando um job roda.

**No console:**

1. Abra o [Amazon EMR](https://console.aws.amazon.com/emr/) e, no menu lateral,
   vá em **EMR Serverless** (a primeira vez pode pedir para criar um **EMR Studio**:
   aceite a criação padrão e continue).
2. Clique em **Create application**.
3. **Name:** `lab-pdn-emrs` · **Type:** **Spark** · **Release version:**
   `emr-7.1.0`.
4. Em **Application setup options**, mantenha **Use default settings for batch jobs
   only** (ou equivalente, dependendo da versão do console).
5. Clique em **Create application** (ou **Create and start application**).

**Como saber que deu certo:** a Application `lab-pdn-emrs` aparece na lista com
estado **Created** (ou **Started**). Anote o **Application ID**.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
APP_ID=$(aws emr-serverless create-application \
  --name "lab-pdn-emrs" --type "SPARK" \
  --release-label "emr-7.1.0" \
  --region "$REGION" --query 'applicationId' --output text)
echo "Application: $APP_ID"
```

</details>

## 4. Submeter o job PySpark (AQUI começa o custo)

**Porquê:** este é o ponto do lab — Spark serverless, cobrança só pelo tempo do job.

**No console:**

1. Em **EMR Serverless**, abra a Application `lab-pdn-emrs` e clique em
   **Submit job run**.
2. **Name:** `lab-pdn-job` (qualquer nome).
3. **Runtime role:** selecione `EMRServerlessJobRole`.
4. **Script location:** `s3://SEU-BUCKET/scripts/job.py`.
5. **Script arguments:** informe os dois argumentos, nesta ordem (entrada e saída):
   `["s3://SEU-BUCKET/raw/jogos.json","s3://SEU-BUCKET/out/"]`
6. Deixe o restante como padrão e clique em **Submit job run**.

**Como saber que deu certo:** na aba **Job runs**, o estado passa por **Pending →
Scheduled → Running → Success** (leva alguns minutos; boa parte é o
provisionamento sob demanda).

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
RUN_ID=$(aws emr-serverless start-job-run \
  --application-id "$APP_ID" \
  --execution-role-arn "arn:aws:iam::${ACCOUNT_ID}:role/$RUNTIME_ROLE" \
  --job-driver "{\"sparkSubmit\":{\"entryPoint\":\"s3://$BUCKET/scripts/job.py\",\"entryPointArguments\":[\"s3://$BUCKET/raw/jogos.json\",\"s3://$BUCKET/out/\"]}}" \
  --region "$REGION" --query 'jobRunId' --output text)

# acompanhe o estado (PENDING -> RUNNING -> SUCCESS)
aws emr-serverless get-job-run --application-id "$APP_ID" --job-run-id "$RUN_ID" \
  --query 'jobRun.state'
```

</details>

## 5. Conferir a saída no S3

**Porquê:** o resultado do job não fica no EMR: ele foi gravado no S3, de onde
qualquer outra ferramenta (Athena, Glue) pode ler.

**No console:** abra o [Amazon S3](https://console.aws.amazon.com/s3/), entre no
seu bucket e na pasta `out/`.

**Como saber que deu certo:** há arquivos `part-*.parquet` (comprimidos com gzip)
dentro de `out/`.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws s3 ls "s3://$BUCKET/out/" --recursive
```

</details>

## 6. (Obrigatório 2) Dependências Python

**Porquê:** jobs reais usam libs que não vêm no runtime. O padrão é empacotar um
**virtualenv** (`--archives` com `venv-pack`) ou usar `--py-files`.

Este passo é **preparação com terminal** (criar o virtualenv, empacotar e enviar
ao S3 não tem equivalente no console), então o caminho é o exemplo oficial,
rodado no terminal ou no [AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1):

- Siga o exemplo **Python Dependencies** do repositório oficial
  [emr-serverless-samples](https://github.com/aws-samples/emr-serverless-samples):
  crie o pacote de dependências, suba no S3 e referencie no `sparkSubmit` via
  `--archives`/`spark.archives`. No console, essa referência entra em **Submit
  job run > Spark properties** (ou **Job configuration**, dependendo da versão).

**Como saber que deu certo:** o job que importa a lib termina em **Success**.

## 7. (Extra) Hive query no EMR Serverless

**Porquê:** mostra que a Application também roda **Hive**, não só Spark. Crie uma
Application do tipo `HIVE` (mesmo caminho do passo 3, trocando o **Type** para
**Hive**) e submeta uma query. Veja o exemplo correspondente no repositório
oficial [emr-serverless-samples](https://github.com/aws-samples/emr-serverless-samples).

## Limpeza

Terminou? Apague o que criou para não gerar cobrança: siga a seção
[**Limpeza** do README deste lab](https://github.com/obernardocosta/big-data/blob/main/disciplinas/pdn/labs/lab-01-emr-serverless/README.md#limpeza).

## Encontrou um problema neste lab?

Um passo não bate com o que você vê no console, um menu mudou de nome ou algo
deu erro? **Abra uma issue** e ajude a melhorar a disciplina:
[abrir issue sobre o PDN Lab 01](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BPDN+Lab+01%5D+&labels=lab).
Diga o passo, o que esperava e o que aconteceu (um print ajuda).
