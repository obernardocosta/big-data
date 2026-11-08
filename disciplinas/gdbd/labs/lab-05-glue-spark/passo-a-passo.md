# Lab 05 — Passo a passo

> **Como usar este roteiro**
>
> 1. Assista à **demo ao vivo** do instrutor (ele mostra os passos 3 a 5 uma vez).
> 2. Repita você mesmo **no console da AWS**, seguindo as instruções de cada passo.
> 3. Travou ou está sem tempo? Os passos têm um bloco **"Prefere o terminal?"**
>    (recolhido) com o mesmo passo em **AWS CLI**. Clique para abrir. Os passos de
>    preparação (1, 2 e 2b) usam o script como caminho principal, e o texto
>    explica por quê.
>
> ⚠️ **Aviso:** a AWS muda nomes de menus e botões com frequência. Se algo não
> estiver exatamente como descrito, procure pelo **objetivo** do passo, use o
> script recolhido ou abra uma issue (link no fim). Isso também ajuda os próximos alunos.

> **Lembrete de custo:** o passo 4 **executa** o Glue Job e é cobrado por
> DPU-hora. Mantenha 2 DPU e um job curto. Faça a Limpeza ao final.

**Console da AWS:** <https://console.aws.amazon.com/> · região **N. Virginia
(`us-east-1`)**, confira no canto superior direito.

Os passos 1, 2 e 2b são scripts: rode-os no terminal ou no
[AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1)
(terminal no navegador, já com a AWS CLI e o Python). Comece definindo as variáveis:

```bash
export BUCKET="gdbd-lab05-$(whoami)-$RANDOM"
export REGION="us-east-1"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export ROLE="GlueCrawlerLabRole"   # reutilizada do Lab 02 (precisa de acesso ao S3 do lab)
echo "$BUCKET"   # anote este nome: você vai usá-lo nos passos seguintes
```

## 1. Subir o CSV cru e o script do job no S3

**Porquê:** o Spark lê a entrada do S3 e o Glue busca o script do job também no
S3. Separamos entrada (`raw/`), saída (`parquet/`) e código (`scripts/`).

Este passo é **preparação**, não conceito do lab: gerar o CSV a partir do JSON
(com `curl` + Python) não tem um equivalente simples no console. Por isso aqui o
**script é o caminho principal** (ele também cria o bucket no
[Amazon S3](https://console.aws.amazon.com/s3/)):

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

# CSV cru REAL: jogos da Premier League 2024/25 (openfootball, cópia no repo data)
curl -s https://raw.githubusercontent.com/obernardocosta/data/main/football/premier-league/2024-25/en.1.json \
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

**Como saber que deu certo:** no [S3](https://console.aws.amazon.com/s3/), abra o
seu bucket > pasta `raw/` e veja o arquivo `premier.csv`.

## 2. Escrever o script PySpark do job

**Porquê:** aqui está a transformação em si — manter só as colunas pedidas e
gravar em Parquet comprimido. É o Spark fazendo o trabalho distribuído.

Também é **preparação**: criar um arquivo `.py` e enviá-lo ao S3 é mais direto
por script, então o **script é o caminho principal**. Leia o código com calma: é
ele que o Glue vai executar no passo 3.

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

**Como saber que deu certo:** no S3, a pasta `scripts/` do seu bucket tem o
arquivo `transforma.py`.

## 2b. Dar à role permissão de GRAVAR no bucket do lab

**Porquê:** a `GlueCrawlerLabRole` do Lab 02 só **lê** o S3 (o Crawler não grava
dados). Este job grava o Parquet, então a role precisa de escrita. Damos o
mínimo: só nos buckets `gdbd-lab*`, não no S3 inteiro. Sem isso o job falha
com `not authorized to perform: s3:PutObject`.

Uma política IAM em JSON é longa e fácil de errar ao digitar no console, então
aqui também o **script é o caminho principal**:

```bash
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

**Como saber que deu certo:** no [IAM](https://console.aws.amazon.com/iam/) >
**Roles** > `GlueCrawlerLabRole` > aba **Permissions**, aparece a política em
linha (*inline*) `GlueLabS3Write`.

## 3. Criar o Glue Job (ainda NÃO executa nada)

**Porquê:** criar o job é só registrar metadados — não gera custo. O custo vem
quando o job **roda** (passo 4). Fixamos 2 DPU para manter barato.

**No console:**

1. Abra o [AWS Glue](https://console.aws.amazon.com/glue/) e, no menu lateral,
   vá em **ETL jobs** (ou **Jobs**, dependendo da versão do console).
2. Escolha **Script editor**, em **Engine** selecione **Spark** e clique em
   **Create script** (ou **Start fresh**, dependendo da versão).
3. Apague o código de exemplo e **cole o conteúdo do `transforma.py`** do passo 2
   (se quiser, rode `cat transforma.py` no terminal e copie).
4. Na aba **Job details**, preencha:
   - **Name:** `lab05-transforma-premier`
   - **IAM Role:** `GlueCrawlerLabRole`
   - **Type:** Spark · **Glue version:** `Glue 4.0`
   - **Worker type:** `G 1X` · **Requested number of workers:** `2`
5. Clique em **Save**.

> **Diferença para o script:** pelo console, o Glue guarda o código num bucket
> próprio dele (`aws-glue-assets-...`). No script, o job aponta para o
> `transforma.py` do seu bucket. O resultado do lab é o mesmo.

**Como saber que deu certo:** o job `lab05-transforma-premier` aparece na lista de
**ETL jobs**, ainda sem nenhuma execução (**Runs** vazio).

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws glue create-job \
  --name lab05-transforma-premier \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/$ROLE" \
  --glue-version "4.0" \
  --number-of-workers 2 --worker-type G.1X \
  --command "Name=glueetl,ScriptLocation=s3://$BUCKET/scripts/transforma.py,PythonVersion=3"
```

</details>

## 4. Executar o job (AQUI começa o custo)

**Porquê:** este é o ponto do lab — Spark distribuído, serverless. Passamos a
entrada e a saída como parâmetros do script.

**No console:**

1. Abra o job `lab05-transforma-premier`. Na aba **Job details**, abra
   **Advanced properties** e, em **Job parameters**, adicione dois parâmetros
   (troque `SEU-BUCKET` pelo valor de `$BUCKET`) e salve:

   | Key | Value |
   |---|---|
   | `--INPUT` | `s3://SEU-BUCKET/raw/` |
   | `--OUTPUT` | `s3://SEU-BUCKET/parquet/` |

   (Alternativa: **Actions > Run with parameters**, que pede os mesmos valores na
   hora de executar.)
2. Clique em **Run** (ou **Run job**).
3. Abra a aba **Runs** e acompanhe a coluna **Run status**: `Running` →
   `Succeeded`.

**Como saber que deu certo:** o status da execução chega a **Succeeded**
(~1–2 min, boa parte é o *cold start* do Spark). Se der `Failed`, veja a coluna
**Error** e o [troubleshooting](troubleshooting.md).

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
RUN_ID=$(aws glue start-job-run --job-name lab05-transforma-premier \
  --arguments "{\"--INPUT\":\"s3://$BUCKET/raw/\",\"--OUTPUT\":\"s3://$BUCKET/parquet/\"}" \
  --query 'JobRunId' --output text)

# acompanhe o estado (RUNNING -> SUCCEEDED)
aws glue get-job-run --job-name lab05-transforma-premier --run-id "$RUN_ID" \
  --query 'JobRun.JobRunState'
```

</details>

## 5. Conferir o Parquet gerado

**Porquê:** validar que a transformação saiu no formato certo antes de consultar.

**No console:**

1. Abra o [Amazon S3](https://console.aws.amazon.com/s3/) > seu bucket > pasta
   `parquet/`.
2. Veja os arquivos `part-...parquet` gerados pelo Spark.

**Como saber que deu certo:** a pasta `parquet/` contém um ou mais arquivos
`.parquet` (o tamanho é bem menor que o do CSV de `raw/`).

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws s3 ls "s3://$BUCKET/parquet/" --recursive
```

</details>

## 6. Consultar no Athena e comparar o scan

**Porquê:** fechar o ciclo com a Aula 2 — o Parquet colunar escaneia menos que o
CSV. Catalogamos as **duas** versões do mesmo dado (CSV cru e Parquet) e rodamos
a mesma pergunta nas duas.

**No console:** abra o [Amazon Athena](https://console.aws.amazon.com/athena/) e
use o **Query editor** (lembre de configurar o local de resultados, como no
Lab 03). Rode as consultas abaixo, trocando `SEU-BUCKET` pelo valor de `$BUCKET`:

```sql
CREATE DATABASE IF NOT EXISTS lab05;

-- o mesmo dado, em CSV (entrada do job)
CREATE EXTERNAL TABLE lab05.premier_csv (
  Date string, HomeTeam string, AwayTeam string, FTHG string, FTAG string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION 's3://SEU-BUCKET/raw/'
TBLPROPERTIES ('skip.header.line.count'='1');

-- e em Parquet (saida do job)
CREATE EXTERNAL TABLE lab05.premier_parquet (
  Date string, HomeTeam string, AwayTeam string, FTHG string, FTAG string)
STORED AS PARQUET
LOCATION 's3://SEU-BUCKET/parquet/';

-- jogos por mes (Date vem como AAAA-MM-DD)
SELECT substr(Date, 1, 7) AS mes, COUNT(*) AS jogos
FROM lab05.premier_parquet
GROUP BY substr(Date, 1, 7) ORDER BY mes;

-- quem mais marcou em casa: rode nas DUAS tabelas e compare o "Data scanned"
SELECT HomeTeam, SUM(CAST(FTHG AS integer)) AS gols_casa
FROM lab05.premier_parquet
GROUP BY HomeTeam ORDER BY gols_casa DESC LIMIT 5;
```

**Como saber que deu certo:** 10 meses (2024-08 a 2025-05), 380 jogos no total, e no
ranking Manchester City FC 43, Liverpool FC 42. O "Data scanned" do Parquet é
**bem menor** que o do CSV para a mesma pergunta: o Parquet lê só as colunas
usadas (medido: **~0,8 KB** no Parquet contra **~19 KB** no CSV, cerca de 20x
menos, para a mesma resposta).

## Limpeza

Terminou? Apague o que criou para não gerar cobrança (e **não deixe o job
agendado**): siga a seção
[**Limpeza** do README deste lab](https://github.com/obernardocosta/big-data/blob/main/disciplinas/gdbd/labs/lab-05-glue-spark/README.md#limpeza).

## Encontrou um problema neste lab?

Um passo não bate com o que você vê no console, um menu mudou de nome ou algo
deu erro? **Abra uma issue** e ajude a melhorar a disciplina:
[abrir issue sobre o GDBD Lab 05](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+05%5D+&labels=lab).
Diga o passo, o que esperava e o que aconteceu (um print ajuda).
