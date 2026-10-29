# Lab 07 — Passo a passo

> Rode o `dry-run.sh` deste lab antes da aula. Ele valida credencial, região,
> usuário IAM, a role do Glue e as permissões de S3/Glue/Athena — read-only, sem
> rodar o Job de transformação (que é o único passo com custo relevante).

```bash
export BUCKET="gdbd-lab07-$(whoami)-$RANDOM"
export REGION="us-east-1"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export ROLE="GlueCrawlerLabRole"
export DB="datalake_premier"
```

## 1. Criar o bucket com as 3 camadas e os dados originais (Raw)

**Porquê:** a camada **Raw** guarda o dado **como veio**, intocado. É a fonte
única de confiança — sempre dá para reprocessar a partir dela.

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

# camada Raw: jogos reais crus da Premier League 2024/25 (openfootball)
curl -s https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json \
  | python3 -c "
import json,sys,csv
dados=json.load(sys.stdin); w=csv.writer(sys.stdout)
w.writerow(['Date','HomeTeam','AwayTeam','FTHG','FTAG'])
for m in dados['matches']:
    ft=(m.get('score') or {}).get('ft') or [None,None]
    w.writerow([m.get('date'),m.get('team1'),m.get('team2'),ft[0],ft[1]])
" > premier.csv
aws s3 cp premier.csv "s3://$BUCKET/raw/premier/premier.csv"
```

## 2. Criar o database do Data Lake

**Porquê:** um database do catálogo agrupa as tabelas das camadas. Catalogar é a
prática nº 3 das boas práticas de Data Lake.

```bash
aws glue create-database --database-input "{\"Name\":\"$DB\"}"
```

## 3. Transformar Raw → Clean com um Glue Job (custo aqui)

**Porquê:** a camada **Clean** padroniza o dado (colunas úteis, formato único da
organização: Parquet + gzip). É a mesma mecânica do Lab 05.

```bash
cat > raw_to_clean.py <<'PY'
import sys
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
args = getResolvedOptions(sys.argv, ["INPUT", "OUTPUT"])
spark = GlueContext(SparkContext()).spark_session
df = (spark.read.option("header", True).csv(args["INPUT"])
      .select("Date", "HomeTeam", "AwayTeam", "FTHG", "FTAG"))
df.write.mode("overwrite").option("compression", "gzip").parquet(args["OUTPUT"])
PY
aws s3 cp raw_to_clean.py "s3://$BUCKET/scripts/raw_to_clean.py"

aws glue create-job --name lab07-raw-to-clean \
  --role "arn:aws:iam::$ACCOUNT_ID:role/$ROLE" \
  --glue-version "4.0" --number-of-workers 2 --worker-type G.1X \
  --command "Name=glueetl,ScriptLocation=s3://$BUCKET/scripts/raw_to_clean.py,PythonVersion=3"

aws glue start-job-run --job-name lab07-raw-to-clean \
  --arguments "--INPUT=s3://$BUCKET/raw/premier/,--OUTPUT=s3://$BUCKET/clean/premier/"
```

## 4. Catalogar a camada Clean com um Crawler

**Porquê:** uma vez limpo e no formato padrão, o dado "faz sentido" — então
catalogamos (boa prática nº 3) para consultar no Athena.

```bash
aws glue create-crawler --name crawler-datalake \
  --role "arn:aws:iam::$ACCOUNT_ID:role/$ROLE" \
  --database-name "$DB" \
  --targets "{\"S3Targets\":[{\"Path\":\"s3://$BUCKET/clean/premier/\"}]}"

aws glue start-crawler --name crawler-datalake
aws glue get-crawler --name crawler-datalake --query 'Crawler.State'
```

## 5. Gerar a camada Specialized (consumo)

**Porquê:** a camada **Specialized** entrega o dado **pronto para o consumidor
final** — aqui, um agregado por time. Pode ser um `CREATE TABLE AS SELECT`
(CTAS) do Athena gravando no S3.

```sql
CREATE TABLE datalake_premier.gols_por_time
WITH (format = 'PARQUET', external_location = 's3://SEU-BUCKET/specialized/gols_por_time/')
AS
SELECT hometeam AS time, SUM(CAST(fthg AS integer)) AS gols_casa
FROM datalake_premier.premier
GROUP BY hometeam;
```

## 6. Consumir a camada final

```sql
SELECT * FROM datalake_premier.gols_por_time ORDER BY gols_casa DESC;
```

## Mapa mental (o que foi usado de cada aula)

```text
Raw (S3)  --Glue Job (Aula 3)-->  Clean (S3, Parquet)
Clean     --Crawler/Catalog (Aulas 1-2)-->  catalogado
Catalogado --Athena CTAS (Aula 2)-->  Specialized (consumo)
```

## Limpeza

Veja a seção "Limpeza" do `README.md`.
