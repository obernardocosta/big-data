# Lab 07 — Passo a passo

> **Como usar este roteiro**
>
> 1. Assista à **demo ao vivo** do instrutor (ele mostra os passos 2 a 5 uma vez).
> 2. Repita você mesmo **no console da AWS**, seguindo as instruções de cada passo.
> 3. Travou ou está sem tempo? Os passos têm um bloco **"Prefere o terminal?"**
>    (recolhido) com o mesmo passo em **AWS CLI**. Clique para abrir. Os passos de
>    preparação (1 e a primeira parte do 3) usam o script como caminho principal,
>    e o texto explica por quê.

**Console da AWS:** <https://console.aws.amazon.com/> · região **N. Virginia
(`us-east-1`)**, confira no canto superior direito.

Os passos de script rodam no terminal ou no
[AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1)
(terminal no navegador, já com a AWS CLI e o Python). Comece definindo as variáveis:

```bash
export BUCKET="gdbd-lab07-$(whoami)-$RANDOM"
export REGION="us-east-1"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export ROLE="GlueCrawlerLabRole"
export DB="datalake_premier"
echo "$BUCKET"   # anote este nome: você vai usá-lo nos passos seguintes
```

## 1. Criar o bucket com as 3 camadas e os dados originais (Raw)

**Porquê:** a camada **Raw** guarda o dado **como veio**, intocado. É a fonte
única de confiança — sempre dá para reprocessar a partir dela.

Este passo é **preparação**: gerar o CSV a partir do JSON (com `curl` + Python)
não tem um equivalente simples no console. Por isso aqui o **script é o caminho
principal** (ele também cria o bucket no
[Amazon S3](https://console.aws.amazon.com/s3/)):

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

# camada Raw: jogos reais crus da Premier League 2024/25 (openfootball, cópia no repo data)
curl -s https://raw.githubusercontent.com/obernardocosta/data/main/football/premier-league/2024-25/en.1.json \
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

**Como saber que deu certo:** no [S3](https://console.aws.amazon.com/s3/), abra o
seu bucket > `raw/premier/` e veja o arquivo `premier.csv`.

## 2. Criar o database do Data Lake

**Porquê:** um database do catálogo agrupa as tabelas das camadas. Catalogar é a
prática nº 3 das boas práticas de Data Lake.

**No console:**

1. Abra o [AWS Glue](https://console.aws.amazon.com/glue/) e, no menu lateral, vá
   em **Data Catalog > Databases**.
2. Clique em **Add database**.
3. Em **Name**, digite `datalake_premier` e clique em **Create database**.

**Como saber que deu certo:** o database `datalake_premier` aparece na lista.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws glue create-database --database-input "{\"Name\":\"$DB\"}"
```

</details>

## 3. Transformar Raw → Clean com um Glue Job (custo aqui)

**Porquê:** a camada **Clean** padroniza o dado (colunas úteis, formato único da
organização: Parquet + gzip). É a mesma mecânica do Lab 05.

### 3a. Preparar o script PySpark e a permissão de escrita

Escrever o `raw_to_clean.py` e a política IAM em JSON é **preparação**, sem
equivalente simples no console (a política é longa e fácil de errar ao digitar).
Por isso aqui o **script é o caminho principal**:

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

# a role precisa GRAVAR na camada Clean (mesmo passo 2b do Lab 05; se ja fez
# o Lab 05, este comando so reaplica a mesma politica, sem efeito colateral)
cat > s3-write-lab.json <<'JSON'
{ "Version": "2012-10-17",
  "Statement": [{ "Effect": "Allow",
    "Action": ["s3:GetObject","s3:PutObject","s3:DeleteObject","s3:ListBucket"],
    "Resource": ["arn:aws:s3:::gdbd-lab*", "arn:aws:s3:::gdbd-lab*/*"] }] }
JSON
aws iam put-role-policy --role-name "$ROLE" \
  --policy-name GlueLabS3Write --policy-document file://s3-write-lab.json
sleep 15   # propagacao do IAM
```

**Como saber que deu certo:** no S3, a pasta `scripts/` tem o `raw_to_clean.py`; e
no [IAM](https://console.aws.amazon.com/iam/) > **Roles** > `GlueCrawlerLabRole` >
**Permissions** aparece a política em linha `GlueLabS3Write`.

### 3b. Criar e executar o Glue Job

**No console:**

1. No [AWS Glue](https://console.aws.amazon.com/glue/), vá em **ETL jobs** (ou
   **Jobs**, dependendo da versão do console) > **Script editor**, engine **Spark**,
   e clique em **Create script** (ou **Start fresh**).
2. Apague o exemplo e **cole o conteúdo do `raw_to_clean.py`** (`cat raw_to_clean.py`
   no terminal).
3. Na aba **Job details**:
   - **Name:** `lab07-raw-to-clean`
   - **IAM Role:** `GlueCrawlerLabRole`
   - **Glue version:** `Glue 4.0` · **Worker type:** `G 1X` · **Requested number of workers:** `2`
   - Em **Advanced properties > Job parameters**, adicione (troque `SEU-BUCKET` pelo
     valor de `$BUCKET`):

     | Key | Value |
     |---|---|
     | `--INPUT` | `s3://SEU-BUCKET/raw/premier/` |
     | `--OUTPUT` | `s3://SEU-BUCKET/clean/premier/` |
4. Clique em **Save** e depois em **Run** (ou **Run job**).
5. Abra a aba **Runs** e **espere o `Succeeded`** (~1–2 min) antes do passo 4: o
   Crawler precisa do Parquet já gravado em `clean/`, senão não encontra nada
   para catalogar.

**Como saber que deu certo:** a execução está em **Succeeded** e o S3 tem arquivos
`.parquet` em `clean/premier/`.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws glue create-job --name lab07-raw-to-clean \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/$ROLE" \
  --glue-version "4.0" --number-of-workers 2 --worker-type G.1X \
  --command "Name=glueetl,ScriptLocation=s3://$BUCKET/scripts/raw_to_clean.py,PythonVersion=3"

RUN_ID=$(aws glue start-job-run --job-name lab07-raw-to-clean \
  --arguments "{\"--INPUT\":\"s3://$BUCKET/raw/premier/\",\"--OUTPUT\":\"s3://$BUCKET/clean/premier/\"}" \
  --query 'JobRunId' --output text)

# ESPERE o SUCCEEDED (~1-2 min) antes do passo 4: o Crawler precisa do Parquet
# ja gravado em clean/, senao ele nao encontra nada para catalogar
aws glue get-job-run --job-name lab07-raw-to-clean --run-id "$RUN_ID" \
  --query 'JobRun.JobRunState'
aws s3 ls "s3://$BUCKET/clean/premier/"
```

</details>

## 4. Catalogar a camada Clean com um Crawler

**Porquê:** uma vez limpo e no formato padrão, o dado "faz sentido" — então
catalogamos (boa prática nº 3) para consultar no Athena.

**No console:**

1. No [AWS Glue](https://console.aws.amazon.com/glue/), vá em **Data Catalog >
   Crawlers** (ou **Crawlers**) e clique em **Create crawler**.
2. **Name:** `crawler-datalake`. Avance.
3. **Data source:** **Add a data source** > **S3**, em **S3 path** informe a
   **pasta** `s3://SEU-BUCKET/clean/premier/` (com barra no final) e confirme.
   Avance.
4. **IAM role:** escolha `GlueCrawlerLabRole`. Avance.
5. **Target database:** `datalake_premier` · **Crawler schedule:** `On demand`.
   Avance, revise e clique em **Create crawler**.
6. Na lista de crawlers, selecione `crawler-datalake` e clique em **Run**.
7. Espere o estado voltar a **Ready** (`Running` → `Stopping` → `Ready`, ~1–2 min).

**Como saber que deu certo:** em **Data Catalog > Tables**, a tabela `premier`
(nome da pasta) aparece no database `datalake_premier`, com as 5 colunas.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws glue create-crawler --name crawler-datalake \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/$ROLE" \
  --database-name "$DB" \
  --targets "{\"S3Targets\":[{\"Path\":\"s3://$BUCKET/clean/premier/\"}]}"

aws glue start-crawler --name crawler-datalake
# RUNNING -> STOPPING -> READY (~1-2 min). Quando READY, a tabela 'premier'
# (nome da pasta) aparece no database:
aws glue get-crawler --name crawler-datalake --query 'Crawler.State'
aws glue get-tables --database-name "$DB" --query 'TableList[].Name'
```

</details>

## 5. Gerar a camada Specialized (consumo)

**Porquê:** a camada **Specialized** entrega o dado **pronto para o consumidor
final** — aqui, um agregado por time. Pode ser um `CREATE TABLE AS SELECT`
(CTAS) do Athena gravando no S3.

**No console:** abra o [Amazon Athena](https://console.aws.amazon.com/athena/) >
**Query editor**, escolha o database `datalake_premier` (e configure o local de
resultados, como no Lab 03). Rode, trocando `SEU-BUCKET` pelo valor de `$BUCKET`:

```sql
CREATE TABLE datalake_premier.gols_por_time
WITH (format = 'PARQUET', external_location = 's3://SEU-BUCKET/specialized/gols_por_time/')
AS
SELECT hometeam AS time, SUM(CAST(fthg AS integer)) AS gols_casa
FROM datalake_premier.premier
GROUP BY hometeam;
```

**Como saber que deu certo:** a tabela `gols_por_time` aparece no database, e o S3
tem arquivos em `specialized/gols_por_time/`.

## 6. Consumir a camada final

**Porquê:** é o ponto de chegada do Data Lake — o consumidor final lê só o agregado
pronto, sem tocar na Raw nem na Clean.

**No console:** no mesmo editor do [Athena](https://console.aws.amazon.com/athena/):

```sql
SELECT * FROM datalake_premier.gols_por_time ORDER BY gols_casa DESC;
```

**Como saber que deu certo:** a consulta lista os times por gols em casa (no topo,
Manchester City FC 43 e Liverpool FC 42).

## Mapa mental (o que foi usado de cada aula)

```text
Raw (S3)  --Glue Job (Aula 3)-->  Clean (S3, Parquet)
Clean     --Crawler/Catalog (Aulas 1-2)-->  catalogado
Catalogado --Athena CTAS (Aula 2)-->  Specialized (consumo)
```

## Limpeza

Terminou? Apague o que criou para não gerar cobrança (o Glue Job é o único item
com custo relevante, mas apague tudo): siga a seção
[**Limpeza** do README deste lab](https://github.com/obernardocosta/big-data/blob/main/disciplinas/gdbd/labs/lab-07-data-lake/README.md#limpeza).

## Encontrou um problema neste lab?

Um passo não bate com o que você vê no console, um menu mudou de nome ou algo
deu erro? **Abra uma issue** e ajude a melhorar a disciplina:
[abrir issue sobre o GDBD Lab 07](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+07%5D+&labels=lab).
Diga o passo, o que esperava e o que aconteceu (um print ajuda).
