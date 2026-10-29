# Lab 06 — Passo a passo

> Rode o `dry-run.sh` **reforçado** deste lab na véspera. Ele checa credencial,
> usuário IAM, roles do EMR, **capacidade/quota de EC2 na região** e o par de
> chaves — tudo read-only, **sem subir cluster**. Este é o lab que mais depende
> de preparação prévia.

> **Custo:** o passo 3 **sobe o cluster** e aí começa a cobrança (~US$ 1 total).
> O cluster é criado com `--auto-terminate` (transient): some sozinho ao acabar
> os steps. Ainda assim, confira a limpeza.

```bash
export BUCKET="gdbd-lab06-$(whoami)-$RANDOM"
export REGION="us-east-1"
export KEYNAME="minha-chave-ec2"   # par de chaves EC2 existente (para SSH, opcional)
```

## 1. Preparar dados e script no S3

**Porquê:** com EMRFS, o cluster lê/escreve no S3. Dados e código ficam lá, o
cluster é descartável.

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

# CSV cru REAL: Premier League 2024/25 (openfootball, sem API key)
curl -s https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json \
  | python3 -c "
import json,sys,csv
dados=json.load(sys.stdin); w=csv.writer(sys.stdout)
w.writerow(['Date','HomeTeam','AwayTeam','FTHG','FTAG'])
for m in dados['matches']:
    ft=(m.get('score') or {}).get('ft') or [None,None]
    w.writerow([m.get('date'),m.get('team1'),m.get('team2'),ft[0],ft[1]])
" > premier.csv
aws s3 cp premier.csv "s3://$BUCKET/raw/premier.csv"

cat > etl.py <<'PY'
from pyspark.sql import SparkSession
import sys
spark = SparkSession.builder.appName("lab06-emr").getOrCreate()
df = (spark.read.option("header", True).csv(sys.argv[1])
      .select("Date", "HomeTeam", "AwayTeam", "FTHG", "FTAG"))
df.write.mode("overwrite").option("compression", "gzip").parquet(sys.argv[2])
spark.stop()
PY
aws s3 cp etl.py "s3://$BUCKET/scripts/etl.py"
```

## 2. Garantir as roles de serviço do EMR

**Porquê:** o EMR precisa de duas roles padrão (uma para o serviço, outra para
as instâncias EC2). O comando abaixo cria as default se não existirem — não gera
custo.

```bash
aws emr create-default-roles
```

## 3. Subir um cluster TRANSIENT com um step de ETL (AQUI começa o custo)

**Porquê:** este é o ponto do lab. `--auto-terminate` faz o cluster se encerrar
ao fim dos steps — o padrão econômico (transient). Usamos poucas instâncias
pequenas para manter perto de US$ 1.

```bash
CLUSTER_ID=$(aws emr create-cluster \
  --name "lab06-emr-transient" \
  --release-label emr-7.1.0 \
  --applications Name=Spark \
  --instance-type m5.xlarge --instance-count 2 \
  --use-default-roles \
  --ec2-attributes KeyName="$KEYNAME" \
  --auto-terminate \
  --log-uri "s3://$BUCKET/logs/" \
  --steps "Type=Spark,Name=ETL,ActionOnFailure=CONTINUE,Args=[s3://$BUCKET/scripts/etl.py,s3://$BUCKET/raw/,s3://$BUCKET/parquet/]" \
  --region "$REGION" --query 'ClusterId' --output text)

echo "Cluster: $CLUSTER_ID"
```

## 4. Acompanhar o cluster e o step

**Porquê:** validar que o ETL rodou. Como é transient, o cluster vai para
`TERMINATING` depois do step.

```bash
aws emr describe-cluster --cluster-id "$CLUSTER_ID" \
  --query 'Cluster.Status.State'

aws emr list-steps --cluster-id "$CLUSTER_ID" \
  --query 'Steps[].{Nome:Name,Estado:Status.State}'
```

## 5. Conferir a saída no S3

```bash
aws s3 ls "s3://$BUCKET/parquet/" --recursive
```

## 6. (Extra/desafio) Orquestrar com Step Functions

**Porquê:** liga a Aula 4 (orquestração) ao EMR. A ideia: uma Step Function que
cria o cluster, adiciona o step e aguarda o término.

- Monte uma máquina de estados com os estados
  `createCluster → addStep → (sync) → terminateCluster`.
- **Desafio:** fazer funcionar **sem** solicitar o template pronto — montando a
  partir da documentação dos conectores de EMR no Step Functions.

## Limpeza

> Como o cluster é `--auto-terminate`, ele some ao fim dos steps. Mesmo assim:

```bash
aws emr terminate-clusters --cluster-ids "$CLUSTER_ID"
aws s3 rm "s3://$BUCKET/" --recursive
```

Veja também a seção "Limpeza" do `README.md`.
