# Lab 01 (PDN) — Passo a passo

> Rode o `dry-run.sh` deste lab antes da aula. Ele checa credencial, região,
> usuário IAM e permissões de Kinesis/Firehose/S3/IAM — tudo read-only, sem
> criar o stream (o shard é o que gera custo).

> **Custo:** o passo 2 **cria o stream** (shard-hora) e o passo 3 cria o
> Firehose. Mantenha 1 shard e faça a limpeza ao final.

```bash
export BUCKET="pdn-lab01-$(whoami)-$RANDOM"
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

**Porquê:** o shard é a unidade de capacidade do Kinesis. Um shard basta para o
volume do lab.

```bash
aws kinesis create-stream --stream-name "$STREAM" --shard-count 1 --region "$REGION"

# aguarde ficar ACTIVE
aws kinesis describe-stream-summary --stream-name "$STREAM" \
  --query 'StreamDescriptionSummary.StreamStatus'
```

## 3. Criar a role e o Firehose apontando para o S3

**Porquê:** o Firehose assume uma role para **gravar no S3**. Ele faz buffering
(por tamanho/tempo) e entrega os eventos como arquivos.

```bash
cat > trust-firehose.json <<'JSON'
{ "Version": "2012-10-17",
  "Statement": [{ "Effect": "Allow",
    "Principal": {"Service": "firehose.amazonaws.com"},
    "Action": "sts:AssumeRole" }] }
JSON

aws iam create-role --role-name FirehoseLabRole \
  --assume-role-policy-document file://trust-firehose.json
aws iam attach-role-policy --role-name FirehoseLabRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

STREAM_ARN=$(aws kinesis describe-stream-summary --stream-name "$STREAM" \
  --query 'StreamDescriptionSummary.StreamARN' --output text)

aws firehose create-delivery-stream \
  --delivery-stream-name "$FIREHOSE" \
  --delivery-stream-type KinesisStreamAsSource \
  --kinesis-stream-source-configuration \
      "KinesisStreamARN=$STREAM_ARN,RoleARN=arn:aws:iam::$ACCOUNT_ID:role/FirehoseLabRole" \
  --s3-destination-configuration \
      "RoleARN=arn:aws:iam::$ACCOUNT_ID:role/FirehoseLabRole,BucketARN=arn:aws:s3:::$BUCKET"
```

## 4. Enviar eventos ao stream

**Porquê:** este é o ponto do lab — produzir eventos contínuos, como um app faria.

```bash
for i in $(seq 1 20); do
  aws kinesis put-record --stream-name "$STREAM" \
    --partition-key "u$i" \
    --data "{\"evento\":\"clique\",\"usuario\":\"u$i\",\"ts\":$(date +%s)}"
done
```

## 5. Ver os eventos chegarem no S3

**Porquê:** o Firehose faz buffering (por padrão alguns MB ou ~60–300s). Espere o
buffer e liste o bucket.

```bash
sleep 120
aws s3 ls "s3://$BUCKET/" --recursive
```

> Os arquivos chegam em um prefixo por data (`YYYY/MM/DD/HH/`). Baixe um e
> inspecione: são os eventos JSON que você enviou.

## Limpeza

Veja a seção "Limpeza" do `README.md`. **O shard cobra enquanto o stream
existir** — não esqueça de apagar.
