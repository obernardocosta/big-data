# Lab B (PDN) — Passo a passo

> Rode o `dry-run.sh` antes da aula: checa credencial, região, usuário IAM,
> permissões de Kinesis/Firehose/S3/IAM e a Application EMR Serverless do Lab A —
> tudo read-only, sem criar o stream (o shard é o que gera custo).

> **Custo:** o passo 2 **cria o stream** (shard-hora). Mantenha 1 shard e limpe
> ao final.

Divisão: **passos 1–5 na Aula 2** (Kinesis + Firehose → S3); **passo 6 no sábado**
(Spark Structured Streaming), reusando o EMR Serverless do Lab A.

```bash
export BUCKET="pdn-lab02-$(whoami)-$RANDOM"
export REGION="us-east-1"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export STREAM="lab-pdn-stream"
export FIREHOSE="lab-pdn-firehose"
```

## 1. Criar o bucket de destino

**Porquê:** é onde o Firehose vai depositar o stream — a porta de entrada do
Data Lake para dados em tempo real.

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"
```

## 2. Criar o Data Stream (1 shard) — custo começa aqui

**Porquê:** o shard é a unidade de capacidade do Kinesis; 1 basta para o lab.

```bash
aws kinesis create-stream --stream-name "$STREAM" --shard-count 1 --region "$REGION"
aws kinesis describe-stream-summary --stream-name "$STREAM" \
  --query 'StreamDescriptionSummary.StreamStatus'   # aguarde ACTIVE
```

## 3. Criar a role e o Firehose (Kinesis → S3)

**Porquê:** o Firehose assume uma role para **gravar no S3**, faz buffering (por
tamanho/tempo) e entrega os eventos como arquivos. Zero código de consumo.

```bash
cat > trust-fh.json <<'JSON'
{ "Version":"2012-10-17","Statement":[{"Effect":"Allow",
  "Principal":{"Service":"firehose.amazonaws.com"},"Action":"sts:AssumeRole"}]}
JSON
aws iam create-role --role-name FirehoseLabRole \
  --assume-role-policy-document file://trust-fh.json
aws iam attach-role-policy --role-name FirehoseLabRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam attach-role-policy --role-name FirehoseLabRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess

STREAM_ARN=$(aws kinesis describe-stream-summary --stream-name "$STREAM" \
  --query 'StreamDescriptionSummary.StreamARN' --output text)

# Role recem-criada leva alguns segundos para propagar no IAM. Sem esta pausa
# o Firehose responde "Firehose is unable to assume role" (visto no teste real).
sleep 15

aws firehose create-delivery-stream \
  --delivery-stream-name "$FIREHOSE" \
  --delivery-stream-type KinesisStreamAsSource \
  --kinesis-stream-source-configuration \
    "KinesisStreamARN=$STREAM_ARN,RoleARN=arn:aws:iam::${ACCOUNT_ID}:role/FirehoseLabRole" \
  --extended-s3-destination-configuration \
    "RoleARN=arn:aws:iam::${ACCOUNT_ID}:role/FirehoseLabRole,BucketARN=arn:aws:s3:::$BUCKET,Prefix=eventos/,BufferingHints={SizeInMBs=1,IntervalInSeconds=60}"
```

## 4. Produtor: ler jogos reais e emitir como stream

**Porquê:** este é o coração do lab — transformar dados reais em um **fluxo** de
eventos, como um app faria. Cada gol/partida vira um evento no stream.

```bash
cat > produtor.py <<'PY'
import json, time, urllib.request, boto3, sys

URL = "https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json"
stream = sys.argv[1]
kinesis = boto3.client("kinesis")

dados = json.load(urllib.request.urlopen(URL))
enviados = 0
for m in dados["matches"]:
    ft = (m.get("score") or {}).get("ft") or [None, None]
    evento = {
        "rodada": m.get("round"),
        "data": m.get("date"),
        "mandante": m.get("team1"),
        "visitante": m.get("team2"),
        "gols_mandante": ft[0],
        "gols_visitante": ft[1],
        "ts": time.time(),
    }
    kinesis.put_record(
        StreamName=stream,
        PartitionKey=evento["mandante"] or "x",
        Data=(json.dumps(evento) + "\n").encode(),
    )
    enviados += 1
    if enviados % 20 == 0:
        print(f"{enviados} eventos enviados...")
    time.sleep(0.2)  # simula chegada continua
print(f"Total: {enviados} eventos.")
PY

# ambiente virtual: evita o erro "externally-managed-environment" do Python
# 3.12+ (Homebrew/Linux recentes) e nao mexe no Python do sistema
python3 -m venv .venv
source .venv/bin/activate
pip install boto3 --quiet
python produtor.py "$STREAM"   # ~2 min: 380 eventos, 1 a cada 0,2 s
```

## 5. Ver os eventos chegarem no S3 (via Firehose)

**Porquê:** o Firehose entrega por tamanho/tempo (aqui, ~60s). Espere o buffer.

```bash
sleep 90
aws s3 ls "s3://$BUCKET/eventos/" --recursive
# baixe um arquivo e inspecione: sao os eventos JSON que o produtor enviou
```

> **Fim da parte da Aula 2.** Ponto de parada seguro: eventos no S3.

## 6. (Sábado) Spark Structured Streaming lendo o S3

**Porquê:** fecha a ponte com o Spark Streaming da graduação. Em vez de um socket,
a **fonte é o diretório do S3** que o Firehose alimenta; o Spark processa em
**micro-batches** e mantém agregados atualizados. Rodamos no **EMR Serverless do
Lab A**.

```bash
cat > stream_job.py <<'PY'
import sys
from pyspark.sql import SparkSession, functions as F
from pyspark.sql.types import StructType, StringType, LongType, DoubleType

entrada, saida, chk = sys.argv[1], sys.argv[2], sys.argv[3]
spark = SparkSession.builder.appName("pdn-spark-streaming").getOrCreate()

schema = (StructType()
    .add("rodada", StringType()).add("data", StringType())
    .add("mandante", StringType()).add("visitante", StringType())
    .add("gols_mandante", LongType()).add("gols_visitante", LongType())
    .add("ts", DoubleType()))

# file source = Structured Streaming lendo o diretorio do Firehose em micro-batches.
# O Firehose grava em eventos/AAAA/MM/DD/HH/arquivo e o file source NAO desce em
# subpastas sozinho: o glob */*/*/*/ aponta para as pastas de hora.
stream = (spark.readStream.schema(schema)
          .option("maxFilesPerTrigger", 1)        # 1 arquivo por micro-batch
          .json(entrada.rstrip("/") + "/*/*/*/*/"))

agg = stream.groupBy("mandante").agg(F.sum("gols_mandante").alias("gols_em_casa"))

# O sink de arquivo (parquet) so aceita modo append, e agregacao sem watermark
# precisa de modo complete (a tabela inteira atualizada a cada batch). O
# foreachBatch resolve: a cada micro-batch, regrava o placar completo.
def grava_placar(batch_df, batch_id):
    print(f"micro-batch {batch_id}: {batch_df.count()} times")
    batch_df.write.mode("overwrite").parquet(saida)

query = (agg.writeStream
         .outputMode("complete")
         .foreachBatch(grava_placar)
         .option("checkpointLocation", chk)
         .trigger(processingTime="30 seconds")
         .start())
query.awaitTermination(180)        # roda ~3 min para o lab e encerra
query.stop()
PY
aws s3 cp stream_job.py "s3://$BUCKET/scripts/stream_job.py"

# reutilize a Application EMR Serverless e a RuntimeRole do Lab A
# (se abriu um terminal novo, recupere o APP_ID pelo nome da Application)
export APP_ID=$(aws emr-serverless list-applications \
  --query "applications[?name=='lab-pdn-emrs' && state!='TERMINATED'].id | [0]" \
  --output text)
echo "Application: $APP_ID"

RUN_ID=$(aws emr-serverless start-job-run \
  --application-id "$APP_ID" \
  --execution-role-arn "arn:aws:iam::${ACCOUNT_ID}:role/EMRServerlessJobRole" \
  --job-driver "{\"sparkSubmit\":{\"entryPoint\":\"s3://$BUCKET/scripts/stream_job.py\",\"entryPointArguments\":[\"s3://$BUCKET/eventos/\",\"s3://$BUCKET/agregados/\",\"s3://$BUCKET/checkpoint/\"]}}" \
  --query 'jobRunId' --output text)

# PENDING -> SCHEDULED -> RUNNING (~3 min processando) -> SUCCESS
aws emr-serverless get-job-run --application-id "$APP_ID" --job-run-id "$RUN_ID" \
  --query 'jobRun.state'
```

Confira os agregados:

```bash
aws s3 ls "s3://$BUCKET/agregados/" --recursive
```

## Limpeza

Veja a seção "Limpeza" do `README.md`. **O shard cobra enquanto o stream
existir** — não esqueça de apagar stream e Firehose.
