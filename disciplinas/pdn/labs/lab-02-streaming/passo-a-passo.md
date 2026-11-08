# PDN Lab 02 (Lab B) — Passo a passo

> **Como usar este roteiro**
>
> 1. Assista à **demo ao vivo** do instrutor (ele faz os passos 2, 3 e 5 uma vez).
> 2. Repita você mesmo **no console da AWS**, seguindo as instruções de cada passo.
> 3. Travou ou está sem tempo? Cada passo tem um bloco **"Prefere o terminal?"**
>    (recolhido) com o mesmo passo em **AWS CLI**. Clique para abrir. Os passos de
>    preparação (produtor, job Spark) têm o **script como caminho principal**.
>
> ⚠️ **Aviso:** a AWS muda nomes de menus e botões com frequência. Se algo não
> estiver exatamente como descrito, procure pelo **objetivo** do passo, use o
> script recolhido ou abra uma issue (link no fim). Isso também ajuda os próximos alunos.

> **Custo:** o passo 2 **cria o stream** (shard-hora). Mantenha 1 shard e limpe
> ao final.

**Console da AWS:** <https://console.aws.amazon.com/> · região **N. Virginia
(`us-east-1`)**, confira no canto superior direito.

Divisão: **passos 1–5 na Aula 2** (Kinesis + Firehose → S3); **passo 6 no sábado**
(Spark Structured Streaming), reusando o EMR Serverless do Lab A.

Se for usar o terminal ou o [AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1),
defina antes as variáveis (anote o nome do bucket: ele é único na AWS e você vai
usá-lo nos passos seguintes):

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

**No console:**

1. Abra o [Amazon S3](https://console.aws.amazon.com/s3/) e clique em **Create bucket**.
2. Em **Bucket name**, use o nome que você anotou (ex.: `pdn-lab02-seunome-1234`).
3. Em **AWS Region**, confirme `US East (N. Virginia) us-east-1`.
4. Deixe o restante como padrão e clique em **Create bucket**.

**Como saber que deu certo:** o bucket aparece na lista de buckets do S3.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"
```

</details>

## 2. Criar o Data Stream (1 shard) — custo começa aqui

**Porquê:** o shard é a unidade de capacidade do Kinesis; 1 basta para o lab.

**No console:**

1. Abra o [Amazon Kinesis](https://console.aws.amazon.com/kinesis/) e, em
   **Data streams** (ou **Kinesis Data Streams**), clique em **Create data stream**.
2. **Data stream name:** `lab-pdn-stream`.
3. **Capacity mode:** **Provisioned**, com **Provisioned shards** = `1`
   (o modo *On-demand* também funciona, mas o custo é menos previsível no lab).
4. Clique em **Create data stream**.

**Como saber que deu certo:** o stream aparece com status **Active** (leva
alguns segundos).

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws kinesis create-stream --stream-name "$STREAM" --shard-count 1 --region "$REGION"
# espera o stream ficar ACTIVE (~30 s); o Firehose do passo 4 exige isso
aws kinesis wait stream-exists --stream-name "$STREAM" --region "$REGION"
aws kinesis describe-stream-summary --stream-name "$STREAM" \
  --query 'StreamDescriptionSummary.StreamStatus'   # deve mostrar "ACTIVE"
```

</details>

## 3. Criar a role e o Firehose (Kinesis → S3)

**Porquê:** o Firehose assume uma role para **gravar no S3**, faz buffering (por
tamanho/tempo) e entrega os eventos como arquivos. Zero código de consumo.

**No console:**

1. Abra o [Amazon Data Firehose](https://console.aws.amazon.com/firehose/)
   (antigo Kinesis Data Firehose) e clique em **Create Firehose stream**.
2. **Source:** **Amazon Kinesis Data Streams** · **Destination:** **Amazon S3**.
3. Em **Source settings**, clique em **Browse** e escolha o stream `lab-pdn-stream`.
4. **Firehose stream name:** `lab-pdn-firehose`.
5. Em **Destination settings**, escolha o seu bucket (**Browse**) e, em **S3 bucket
   prefix**, informe `eventos/`.
6. Em **Buffer hints, compression and encryption** (ou **Buffer hints**), ajuste
   **Buffer size** = `1` MiB e **Buffer interval** = `60` segundos.
7. Em **Advanced settings > Service access**, deixe **Create or update IAM role**
   (o console cria a role com permissão de ler o stream e gravar no S3). Isso
   substitui a `FirehoseLabRole` do script.
8. Clique em **Create Firehose stream**.

**Como saber que deu certo:** o Firehose `lab-pdn-firehose` aparece com status
**Active**, com a fonte apontando para `lab-pdn-stream`.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

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

</details>

## 4. Produtor: ler jogos reais e emitir como stream

**Porquê:** este é o coração do lab — transformar dados reais em um **fluxo** de
eventos, como um app faria. Cada gol/partida vira um evento no stream.

Este passo é **preparação**, não conceito do lab: o produtor é um programa
Python (escrever o `produtor.py`, criar o ambiente virtual, instalar o `boto3`)
e não tem equivalente no console. Por isso aqui o **script é o caminho
principal**. Rode no terminal ou no
[AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1)
(terminal no navegador, já com a AWS CLI e o Python):

```bash
cat > produtor.py <<'PY'
import json, time, urllib.request, boto3, sys

URL = "https://raw.githubusercontent.com/obernardocosta/data/main/football/premier-league/2024-25/en.1.json"
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

**Como saber que deu certo:** o terminal imprime `20 eventos enviados...`,
`40 eventos enviados...` e termina com `Total: 380 eventos.` No console do
Kinesis, abra o stream > aba **Monitoring** para ver o gráfico de
**Incoming data / Incoming records** subir (com alguns minutos de atraso).

## 5. Ver os eventos chegarem no S3 (via Firehose)

**Porquê:** o Firehose entrega por tamanho/tempo (aqui, ~60s). Espere o buffer.

**No console:**

1. Aguarde ~1 a 2 minutos depois do fim do produtor.
2. Abra o [Amazon S3](https://console.aws.amazon.com/s3/), entre no seu bucket e na
   pasta `eventos/`. O Firehose cria subpastas por data/hora
   (`AAAA/MM/DD/HH/`).
3. Abra um arquivo e use **Download** (ou **Open**) para inspecionar: são os
   eventos JSON que o produtor enviou, um por linha.

**Como saber que deu certo:** há arquivos dentro de `eventos/AAAA/MM/DD/HH/`.
Se ainda não aparecem, é *buffering*, não erro: espere mais um minuto e atualize.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
sleep 90
aws s3 ls "s3://$BUCKET/eventos/" --recursive
# baixe um arquivo e inspecione: sao os eventos JSON que o produtor enviou
```

</details>

> **Fim da parte da Aula 2.** Ponto de parada seguro: eventos no S3.

## 6. (Sábado) Spark Structured Streaming lendo o S3

**Porquê:** fecha a ponte com o Spark Streaming da graduação. Em vez de um socket,
a **fonte é o diretório do S3** que o Firehose alimenta; o Spark processa em
**micro-batches** e mantém agregados atualizados. Rodamos no **EMR Serverless do
Lab A**.

Este passo é **preparação com código**: escrever o `stream_job.py`, enviá-lo ao S3
e recuperar a Application do Lab A não têm equivalente simples no console. Por
isso o **script é o caminho principal** (terminal ou
[AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1)).

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

**No console (acompanhar, ou submeter no lugar do `start-job-run`):** no
[Amazon EMR](https://console.aws.amazon.com/emr/) > **EMR Serverless**, abra a
Application `lab-pdn-emrs` > **Job runs**. Se preferir submeter pelo console
(igual ao passo 4 do Lab A, depois de enviar o `stream_job.py` ao S3), use
**Submit job run** com a role `EMRServerlessJobRole`, o script
`s3://SEU-BUCKET/scripts/stream_job.py` e os argumentos
`["s3://SEU-BUCKET/eventos/","s3://SEU-BUCKET/agregados/","s3://SEU-BUCKET/checkpoint/"]`.

Confira os agregados no [Amazon S3](https://console.aws.amazon.com/s3/): pasta
`agregados/` do seu bucket.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws s3 ls "s3://$BUCKET/agregados/" --recursive
```

</details>

**Como saber que deu certo:** o job termina em **Success** (~3 min) e há arquivos
Parquet em `agregados/` (gols em casa por time).

## Limpeza

Terminou? Apague o que criou para não gerar cobrança: siga a seção
[**Limpeza** do README deste lab](https://github.com/obernardocosta/big-data/blob/main/disciplinas/pdn/labs/lab-02-streaming/README.md#limpeza).
**O shard cobra enquanto o stream existir** — não esqueça de apagar stream e
Firehose.

## Encontrou um problema neste lab?

Um passo não bate com o que você vê no console, um menu mudou de nome ou algo
deu erro? **Abra uma issue** e ajude a melhorar a disciplina:
[abrir issue sobre o PDN Lab 02](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BPDN+Lab+02%5D+&labels=lab).
Diga o passo, o que esperava e o que aconteceu (um print ajuda).
