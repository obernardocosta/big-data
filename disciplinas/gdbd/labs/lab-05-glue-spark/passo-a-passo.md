# Lab 05 — Passo a passo

> Rode o `dry-run.sh` deste lab antes da aula. Ele checa credencial, região,
> usuário IAM, a role do Glue e as permissões de Glue/S3/Athena — tudo
> read-only, sem rodar o Job (o Job é o que gera custo).

> **Lembrete de custo:** o passo 4 **executa** o Glue Job e é cobrado por
> DPU-hora. Mantenha 2 DPU e um job curto. Faça a Limpeza ao final.

```bash
export BUCKET="gdbd-lab05-$(whoami)-$RANDOM"
export REGION="us-east-1"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export ROLE="GlueCrawlerLabRole"   # reutilizada do Lab 02 (precisa de acesso ao S3 do lab)
```

## 1. Subir o CSV cru e o script do job no S3

**Porquê:** o Spark lê a entrada do S3 e o Glue busca o script do job também no
S3. Separamos entrada (`raw/`), saída (`parquet/`) e código (`scripts/`).

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

# CSV cru REAL: jogos da Premier League 2024/25 (openfootball, sem API key)
curl -s https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json \
  | python3 -c "
import json,sys,csv
dados=json.load(sys.stdin); w=csv.writer(sys.stdout)
w.writerow(['Date','HomeTeam','AwayTeam','FTHG','FTAG'])
for m in dados['matches']:
    ft=(m.get('score') or {}).get('ft') or [None,None]
    w.writerow([m.get('date'),m.get('team1'),m.get('team2'),ft[0],ft[1]])
" > premier.csv

head -3 premier.csv
aws s3 cp premier.csv "s3://$BUCKET/raw/premier.csv"
```

## 2. Escrever o script PySpark do job

**Porquê:** aqui está a transformação em si — manter só as colunas pedidas e
gravar em Parquet comprimido. É o Spark fazendo o trabalho distribuído.

```bash
cat > transforma.py <<'PY'
import sys
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions

args = getResolvedOptions(sys.argv, ["INPUT", "OUTPUT"])
sc = SparkContext()
spark = GlueContext(sc).spark_session

df = (spark.read.option("header", True).csv(args["INPUT"])
      .select("Date", "HomeTeam", "AwayTeam", "FTHG", "FTAG"))

(df.write.mode("overwrite")
   .option("compression", "gzip")
   .parquet(args["OUTPUT"]))
PY
aws s3 cp transforma.py "s3://$BUCKET/scripts/transforma.py"
```

## 3. Criar o Glue Job (ainda NÃO executa nada)

**Porquê:** criar o job é só registrar metadados — não gera custo. O custo vem
quando o job **roda** (passo 4). Fixamos 2 DPU para manter barato.

```bash
aws glue create-job \
  --name lab05-transforma-premier \
  --role "arn:aws:iam::$ACCOUNT_ID:role/$ROLE" \
  --glue-version "4.0" \
  --number-of-workers 2 --worker-type G.1X \
  --command "Name=glueetl,ScriptLocation=s3://$BUCKET/scripts/transforma.py,PythonVersion=3"
```

## 4. Executar o job (AQUI começa o custo)

**Porquê:** este é o ponto do lab — Spark distribuído, serverless. Passamos a
entrada e a saída como parâmetros do script.

```bash
RUN_ID=$(aws glue start-job-run --job-name lab05-transforma-premier \
  --arguments "--INPUT=s3://$BUCKET/raw/,--OUTPUT=s3://$BUCKET/parquet/" \
  --query 'JobRunId' --output text)

# acompanhe o estado (RUNNING -> SUCCEEDED)
aws glue get-job-run --job-name lab05-transforma-premier --run-id "$RUN_ID" \
  --query 'JobRun.JobRunState'
```

## 5. Conferir o Parquet gerado

**Porquê:** validar que a transformação saiu no formato certo antes de consultar.

```bash
aws s3 ls "s3://$BUCKET/parquet/" --recursive
```

## 6. Consultar no Athena e comparar o scan

**Porquê:** fechar o ciclo com a Aula 2 — o Parquet colunar escaneia menos que o
CSV. Catalogue a saída (um Crawler apontando para `s3://$BUCKET/parquet/`, como
no Lab 02) e rode:

```sql
-- jogos por ano
SELECT substr(Date, 7, 4) AS ano, COUNT(*) AS jogos
FROM <DB>.premier_parquet
GROUP BY substr(Date, 7, 4) ORDER BY ano;

-- mes com mais / menos jogos
SELECT substr(Date, 4, 2) AS mes, COUNT(*) AS jogos
FROM <DB>.premier_parquet
GROUP BY substr(Date, 4, 2) ORDER BY jogos DESC;
```

Compare o "Data scanned" com o do mesmo dado em CSV — deve ser menor.

## Limpeza

Veja a seção "Limpeza" do `README.md`. **Não deixe o job agendado.**
