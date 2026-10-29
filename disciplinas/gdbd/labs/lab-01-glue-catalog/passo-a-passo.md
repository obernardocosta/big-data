# Lab 01 — Passo a passo

> Antes de começar, rode o `dry-run.sh` deste lab para garantir que o ambiente
> está pronto (credencial, região, usuário IAM). Ele não cria nada que custe.

Defina uma variável com o nome do seu bucket (precisa ser único na AWS):

```bash
export BUCKET="gdbd-lab01-$(whoami)-$RANDOM"
export REGION="us-east-1"
```

## 1. Criar o bucket no S3

**Porquê:** o catálogo descreve tabelas, mas os dados continuam vivendo como
arquivos no S3. Precisamos de um lugar para eles.

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"
```

## 2. Gerar dados REAIS e enviar ao S3

**Porquê:** a tabela do catálogo vai apontar para um "prefixo" (pasta) no S3.
Em vez de inventar dados, usamos jogos **reais e atuais** da Premier League
2024/25 do projeto público **openfootball** (JSON, sem API key) e geramos um CSV.

```bash
# baixa os jogos reais e gera um CSV com 4 colunas (sem cabecalho de pais ainda)
curl -s https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json \
  | python3 -c "
import json,sys,csv
dados=json.load(sys.stdin); w=csv.writer(sys.stdout)
w.writerow(['data','mandante','visitante','gols_mandante'])
for m in dados['matches']:
    ft=(m.get('score') or {}).get('ft') or [None,None]
    w.writerow([m.get('date'),m.get('team1'),m.get('team2'),ft[0]])
" > jogos.csv

head -3 jogos.csv          # confira o conteudo real
aws s3 cp jogos.csv "s3://$BUCKET/jogos/jogos.csv"
```

## 3. Criar o banco de dados no Glue Data Catalog

**Porquê:** no catálogo, tabelas vivem dentro de um *database* (um agrupamento
lógico), igual ao Hive Metastore.

```bash
aws glue create-database --database-input '{"Name":"futebol"}'
```

## 4. Criar a tabela catalogada

**Porquê:** aqui está o coração do lab — definimos a **visão de tabela** (colunas
e tipos) sobre os arquivos do S3. É isso que o SQL vai enxergar.

```bash
aws glue create-table --database-name futebol --table-input '{
  "Name": "jogos",
  "StorageDescriptor": {
    "Columns": [
      {"Name": "data", "Type": "string"},
      {"Name": "mandante", "Type": "string"},
      {"Name": "visitante", "Type": "string"},
      {"Name": "gols_mandante", "Type": "int"}
    ],
    "Location": "s3://'"$BUCKET"'/jogos/",
    "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
    "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
    "SerdeInfo": {
      "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
      "Parameters": {"field.delim": ","}
    }
  },
  "Parameters": {"classification": "csv", "skip.header.line.count": "1"},
  "TableType": "EXTERNAL_TABLE"
}'
```

Confira no console (Glue > Data Catalog > Tables) ou via CLI:

```bash
aws glue get-table --database-name futebol --name jogos \
  --query 'Table.StorageDescriptor.Columns'
```

## 5. Observar o Schema Evolution

**Porquê:** este é o conceito-chave. Quando a fonte muda (ex.: passamos a
registrar também os gols do visitante), o esquema muda — e o catálogo
**versiona** isso.

Adicione a coluna `gols_visitante` atualizando a tabela:

```bash
aws glue update-table --database-name futebol --table-input '{
  "Name": "jogos",
  "StorageDescriptor": {
    "Columns": [
      {"Name": "data", "Type": "string"},
      {"Name": "mandante", "Type": "string"},
      {"Name": "visitante", "Type": "string"},
      {"Name": "gols_mandante", "Type": "int"},
      {"Name": "gols_visitante", "Type": "int"}
    ],
    "Location": "s3://'"$BUCKET"'/jogos/",
    "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
    "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
    "SerdeInfo": {
      "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
      "Parameters": {"field.delim": ","}
    }
  },
  "Parameters": {"classification": "csv", "skip.header.line.count": "1"},
  "TableType": "EXTERNAL_TABLE"
}'
```

Veja as versões registradas:

```bash
aws glue get-table-versions --database-name futebol --table-name jogos \
  --query 'TableVersions[].VersionId'
```

Você deve ver **mais de uma versão**. Esse é o Schema Evolution em ação.

## Limpeza

Veja a seção "Limpeza" do `README.md`.
