# Lab 01 — Passo a passo

> **Como usar este roteiro**
>
> 1. Assista à **demo ao vivo** do instrutor (ele faz os passos 3 a 5 uma vez).
> 2. Repita você mesmo **no console da AWS**, seguindo as instruções de cada passo.
> 3. Travou ou está sem tempo? Cada passo tem um bloco **"Prefere o terminal?"**
>    (recolhido) com o mesmo passo em **AWS CLI**. Clique para abrir.
>
> ⚠️ **Aviso:** a AWS muda nomes de menus e botões com frequência. Se algo não
> estiver exatamente como descrito, procure pelo **objetivo** do passo, use o
> script recolhido ou abra uma issue (link no fim). Isso também ajuda os próximos alunos.

**Console da AWS:** <https://console.aws.amazon.com/> · região **N. Virginia
(`us-east-1`)**, confira no canto superior direito.

Defina o nome do seu bucket (precisa ser único na AWS). Se for usar o terminal ou
o CloudShell, rode também:

```bash
export BUCKET="gdbd-lab01-$(whoami)-$RANDOM"
export REGION="us-east-1"
echo "$BUCKET"   # anote este nome: você vai usá-lo nos passos seguintes
```

## 1. Criar o bucket no S3

**Porquê:** o catálogo descreve tabelas, mas os dados continuam vivendo como
arquivos no S3. Precisamos de um lugar para eles.

**No console:**

1. Abra o [Amazon S3](https://console.aws.amazon.com/s3/) e clique em **Create bucket**.
2. Em **Bucket name**, use o nome que você anotou (ex.: `gdbd-lab01-seunome-1234`).
3. Em **AWS Region**, confirme `US East (N. Virginia) us-east-1`.
4. Deixe o restante como padrão e clique em **Create bucket**.

**Como saber que deu certo:** o bucket aparece na lista de buckets do S3.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"
```

</details>

## 2. Gerar dados REAIS e enviar ao S3

**Porquê:** a tabela do catálogo vai apontar para um "prefixo" (pasta) no S3.
Em vez de inventar dados, usamos jogos **reais e atuais** da Premier League
2024/25 do projeto público [openfootball](https://github.com/openfootball/football.json) (JSON), copiado no [repo data](https://github.com/obernardocosta/data/tree/main/football), e geramos um CSV.

Este passo é **preparação**, não conceito do lab: converter JSON em CSV não tem
um equivalente simples no console. Por isso aqui o **script é o caminho
principal**. Rode no terminal ou no [AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1)
(terminal no navegador, já com a AWS CLI e o Python):

```bash
# baixa os jogos reais e gera um CSV com 5 colunas. No passo 4 catalogamos so
# as 4 primeiras; no passo 5 (Schema Evolution) o catalogo passa a enxergar a 5a.
curl -s https://raw.githubusercontent.com/obernardocosta/data/main/football/premier-league/2024-25/en.1.json \
  | python3 -c "
import json,sys,csv
dados=json.load(sys.stdin); w=csv.writer(sys.stdout)
w.writerow(['data','mandante','visitante','gols_mandante','gols_visitante'])
for m in dados['matches']:
    ft=(m.get('score') or {}).get('ft') or [None,None]
    w.writerow([m.get('date'),m.get('team1'),m.get('team2'),ft[0],ft[1]])
" > jogos.csv

head -3 jogos.csv          # confira o conteudo real
aws s3 cp jogos.csv "s3://$BUCKET/jogos/jogos.csv"
```

**Como saber que deu certo:** no S3, abra o seu bucket > pasta `jogos/` e veja o
arquivo `jogos.csv`.

## 3. Criar o banco de dados no Glue Data Catalog

**Porquê:** no catálogo, tabelas vivem dentro de um *database* (um agrupamento
lógico), igual ao Hive Metastore.

**No console:**

1. Abra o [AWS Glue](https://console.aws.amazon.com/glue/) e, no menu lateral, vá em
   **Data Catalog > Databases**.
2. Clique em **Add database**.
3. Em **Name**, digite `futebol` e clique em **Create database**.

**Como saber que deu certo:** o database `futebol` aparece na lista.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws glue create-database --database-input '{"Name":"futebol"}'
```

</details>

## 4. Criar a tabela catalogada

**Porquê:** aqui está o coração do lab — definimos a **visão de tabela** (colunas
e tipos) sobre os arquivos do S3. É isso que o SQL vai enxergar.

**No console:**

1. No Glue, vá em **Data Catalog > Tables** e clique em **Add table**
   (ou **Add tables > Add table manually**, dependendo da versão do console).
2. **Name:** `jogos` · **Database:** `futebol`. Avance.
3. **Data store:** Amazon S3. Em **Include path**, informe a **pasta** (não o
   arquivo): `s3://SEU-BUCKET/jogos/`. Avance.
4. **Data format:** **CSV**, com delimitador **Comma**. Avance.
5. **Schema:** adicione **apenas 4 colunas**, nesta ordem (de propósito: a 5ª
   entra no passo 5):

   | Coluna | Tipo |
   |---|---|
   | `data` | string |
   | `mandante` | string |
   | `visitante` | string |
   | `gols_mandante` | int |

6. Avance (sem partições), revise e clique em **Create**.
7. Abra a tabela `jogos`, clique em **Actions > Edit table** e, em **Table
   properties**, adicione a chave `skip.header.line.count` com o valor `1`
   (a primeira linha do CSV é o cabeçalho). Salve.

**Como saber que deu certo:** na página da tabela `jogos`, o **Schema** lista as 4
colunas e a **Location** aponta para `s3://SEU-BUCKET/jogos/`.

**Para pensar:** o arquivo CSV tem 5 colunas, mas a tabela só tem 4. Qual dos dois
é a "verdade" para quem consulta com SQL?

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

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

# conferir as colunas
aws glue get-table --database-name futebol --name jogos \
  --query 'Table.StorageDescriptor.Columns'
```

</details>

## 5. Observar o Schema Evolution

**Porquê:** este é o conceito-chave. Quando a fonte muda (ex.: passamos a
registrar também os gols do visitante), o esquema muda — e o catálogo
**versiona** isso.

O arquivo no S3 já tem a coluna `gols_visitante`, mas a tabela ainda não a
enxerga (se rodar um `SELECT *` no Athena, só aparecem 4 colunas). Repare que o
dado não muda — muda só a **visão de tabela**.

**No console:**

1. Abra a tabela `jogos` no Glue (**Data Catalog > Tables > jogos**).
2. Clique em **Actions > Edit schema** (ou **Edit schema** na aba **Schema**).
3. Clique em **Add**, e crie a coluna `gols_visitante` do tipo `int`, **depois**
   de `gols_mandante`. Salve.
4. Veja as versões: na página da tabela, abra a aba **Schema versions** (em alguns
   consoles: **Actions > View versions**). Compare a versão anterior com a nova
   (**Compare versions**).

**Como saber que deu certo:** a tabela tem **mais de uma versão** e a nova inclui
`gols_visitante`. Esse é o Schema Evolution em ação.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

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

# listar as versões registradas (você deve ver mais de uma)
aws glue get-table-versions --database-name futebol --table-name jogos \
  --query 'TableVersions[].VersionId'
```

</details>

## Limpeza

Terminou? Apague o que criou para não gerar cobrança: siga a seção
[**Limpeza** do README deste lab](https://github.com/obernardocosta/big-data/blob/main/disciplinas/gdbd/labs/lab-01-glue-catalog/README.md#limpeza).

## Encontrou um problema neste lab?

Um passo não bate com o que você vê no console, um menu mudou de nome ou algo
deu erro? **Abra uma issue** e ajude a melhorar a disciplina:
[abrir issue sobre o GDBD Lab 01](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+01%5D+&labels=lab).
Diga o passo, o que esperava e o que aconteceu (um print ajuda).
