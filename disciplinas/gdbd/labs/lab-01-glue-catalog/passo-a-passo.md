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

## 2. Enviar um arquivo de dados

**Porquê:** a tabela do catálogo vai apontar para um "prefixo" (pasta) no S3.
Tudo que estiver sob esse prefixo é lido como dados da tabela.

Crie um CSV simples localmente e envie:

```bash
cat > melhores_jogadores.csv <<'CSV'
jogador,ano,premios
Messi,2023,8
Cristiano Ronaldo,2017,5
Modric,2018,1
CSV

aws s3 cp melhores_jogadores.csv "s3://$BUCKET/melhores_jogadores/melhores_jogadores.csv"
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
  "Name": "melhores_jogadores",
  "StorageDescriptor": {
    "Columns": [
      {"Name": "jogador", "Type": "string"},
      {"Name": "ano", "Type": "int"},
      {"Name": "premios", "Type": "int"}
    ],
    "Location": "s3://'"$BUCKET"'/melhores_jogadores/",
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
aws glue get-table --database-name futebol --name melhores_jogadores \
  --query 'Table.StorageDescriptor.Columns'
```

## 5. Observar o Schema Evolution

**Porquê:** este é o conceito-chave. Quando a fonte muda (ex.: passamos a
registrar o país do jogador), o esquema muda — e o catálogo **versiona** isso.

Adicione uma coluna `pais` atualizando a tabela:

```bash
aws glue update-table --database-name futebol --table-input '{
  "Name": "melhores_jogadores",
  "StorageDescriptor": {
    "Columns": [
      {"Name": "jogador", "Type": "string"},
      {"Name": "ano", "Type": "int"},
      {"Name": "premios", "Type": "int"},
      {"Name": "pais", "Type": "string"}
    ],
    "Location": "s3://'"$BUCKET"'/melhores_jogadores/",
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
aws glue get-table-versions --database-name futebol --table-name melhores_jogadores \
  --query 'TableVersions[].VersionId'
```

Você deve ver **mais de uma versão**. Esse é o Schema Evolution em ação.

## Limpeza

Veja a seção "Limpeza" do `README.md`.
