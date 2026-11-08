# Lab 04 — Passo a passo

> **Como usar este roteiro**
>
> 1. Assista à **demo ao vivo** do instrutor (ele faz os passos 3 a 6 uma vez).
> 2. Repita você mesmo **no console da AWS**, seguindo as instruções de cada passo.
> 3. Travou ou está sem tempo? Cada passo tem um bloco **"Prefere o terminal?"**
>    (recolhido) com o mesmo passo em **AWS CLI**. Clique para abrir.

**Console da AWS:** <https://console.aws.amazon.com/> · região **N. Virginia
(`us-east-1`)**, confira no canto superior direito.

Defina as variáveis do lab. Se for usar o terminal ou o CloudShell, rode também:

```bash
export BUCKET="gdbd-lab04-$(whoami)-$RANDOM"
export REGION="us-east-1"
export RESULTS_BUCKET="gdbd-lab04-results-$(whoami)-$RANDOM"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export DB="futebol_part"
echo "$BUCKET" "$RESULTS_BUCKET"   # anote estes nomes: você vai usá-los nos passos seguintes
```

## 1. Criar o bucket e subir dados JÁ PARTICIONADOS

**Porquê:** a partição é o **nome da pasta**. O Athena vai tratar `year` e
`month` como colunas só porque os arquivos estão organizados assim. A separação
dos dados nas partições é feita por nós (manual neste lab).

Este passo é **preparação**, não conceito do lab: gerar um CSV por partição a
partir do JSON não tem um equivalente simples no console. Por isso aqui o
**script é o caminho principal**. Rode no terminal ou no [AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1)
(terminal no navegador, já com a AWS CLI e o Python). O script também cria o
bucket:

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

# Jogos reais (openfootball 2024/25, cópia no repo data) particionados por ano/mês a partir da DATA
# real de cada partida. Um Python curto lê o JSON e grava um CSV por partição.
curl -s https://raw.githubusercontent.com/obernardocosta/data/main/football/premier-league/2024-25/en.1.json \
  | python3 -c "
import json,sys,csv,os,collections
dados=json.load(sys.stdin)
buckets=collections.defaultdict(list)
for m in dados['matches']:
    d=(m.get('date') or '')[:10]          # YYYY-MM-DD
    if len(d)<7: continue
    y,mo=d[:4],d[5:7]
    ft=(m.get('score') or {}).get('ft') or [None,None]
    buckets[(y,mo)].append([d,m.get('team1'),m.get('team2'),ft[0],ft[1]])
for (y,mo),linhas in buckets.items():
    path=f'part/year={y}/month={mo}'
    os.makedirs(path,exist_ok=True)
    with open(f'{path}/jogos.csv','w',newline='') as f:
        w=csv.writer(f); w.writerow(['data','mandante','visitante','gols_mandante','gols_visitante'])
        w.writerows(linhas)
print('particoes criadas:'); 
"
find part -name '*.csv' | head

# envia a arvore particionada para o S3 (year=.../month=.../)
aws s3 cp part/ "s3://$BUCKET/tabela/" --recursive
```

**Como saber que deu certo:** no [Amazon S3](https://console.aws.amazon.com/s3/),
abra o seu bucket > pasta `tabela/` e veja as subpastas `year=2024/` e
`year=2025/`, cada uma com pastas `month=NN/` e um `jogos.csv` dentro.

## 2. Reaproveitar a role de serviço do Glue

**Porquê:** o Crawler precisa de uma role para ler o S3 e escrever no catálogo —
a mesma lógica do Lab 02. Se já criou a `GlueCrawlerLabRole` lá, reutilize.

**No console:**

1. Abra o [IAM](https://console.aws.amazon.com/iam/) > **Roles** e pesquise
   `GlueCrawlerLabRole`.
2. Se ela **não existir**, crie-a como no
   [passo 2 do Lab 02](https://github.com/obernardocosta/big-data/blob/main/disciplinas/gdbd/labs/lab-02-glue-crawler/passo-a-passo.md#2-criar-a-iam-role-que-o-glue-vai-assumir)
   antes de continuar.

**Como saber que deu certo:** a `GlueCrawlerLabRole` aparece em **Roles**.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws iam get-role --role-name GlueCrawlerLabRole >/dev/null 2>&1 \
  && echo "role ja existe" \
  || echo "crie a role como no Lab 02 (passo 2) antes de continuar"
```

</details>

## 3. Criar o database e o Crawler apontando para a RAIZ da tabela

**Porquê:** apontamos para `s3://.../tabela/` (a raiz), **não** para uma partição
específica. É assim que o Crawler enxerga a estrutura `year/month/day` e a
registra como colunas de partição.

> Se o Crawler falhar com `Account ... is denied access` (restrição de conta
> nova no Glue), pule os passos 3 e 4 e use o **Plano B** no fim desta página: a
> mesma tabela particionada criada por SQL no Athena.

**No console:**

1. No [AWS Glue](https://console.aws.amazon.com/glue/), vá em **Data Catalog >
   Databases**, clique em **Add database**, digite `futebol_part` em **Name** e
   clique em **Create database**.
2. Vá em **Data Catalog > Crawlers** (ou **Crawlers**, dependendo da versão do
   console) e clique em **Create crawler**.
3. **Name:** `crawler-particionado`. Avance.
4. Em **Data sources**, clique em **Add a data source**: **Data source:** S3 ·
   **S3 path:** `s3://SEU-BUCKET/tabela/` (a **raiz**, não `year=.../`) ·
   deixe o restante como padrão e clique em **Add an S3 data source**. Avance.
5. Em **IAM role**, escolha a `GlueCrawlerLabRole`. Avance.
6. Em **Target database**, escolha `futebol_part`; em **Crawler schedule**
   (**Frequency**), deixe **On demand**. Avance.
7. Revise e clique em **Create crawler**.

**Como saber que deu certo:** o database `futebol_part` existe e o
`crawler-particionado` aparece na lista de crawlers com estado **Ready**.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws glue create-database --database-input "{\"Name\":\"$DB\"}"

aws glue create-crawler \
  --name crawler-particionado \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/GlueCrawlerLabRole" \
  --database-name "$DB" \
  --targets "{\"S3Targets\":[{\"Path\":\"s3://$BUCKET/tabela/\"}]}"
```

</details>

## 4. Rodar o Crawler e conferir as colunas de partição

**Porquê:** aqui confirmamos que `year` e `month` viraram **partitionKeys**
da tabela — é o que habilita o filtro otimizado no Athena.

**No console:**

1. Em **Crawlers**, selecione `crawler-particionado` e clique em **Run**.
2. Acompanhe o **State** até voltar a **Ready** (clique no ícone de atualizar;
   leva de segundos a ~2 min).
3. Vá em **Data Catalog > Tables**, abra a tabela criada (provavelmente
   `tabela`, nome da pasta raiz) e olhe o **Schema**: as colunas `year` e
   `month` aparecem marcadas como **Partition** (partition key). Você também
   pode clicar em **View partitions**.

**Como saber que deu certo:** `year` e `month` aparecem como chaves de partição
da tabela, junto com as 5 colunas de dados.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws glue start-crawler --name crawler-particionado
aws glue get-crawler --name crawler-particionado --query 'Crawler.State'

# quando READY, veja as chaves de particao
aws glue get-tables --database-name "$DB" \
  --query 'TableList[].{Nome:Name,Particoes:PartitionKeys[].Name}'
```

</details>

## 5. Consultar COM filtro de partição e medir o scan

**Porquê:** este é o ponto do lab. Filtrar por `year/month` faz o Athena ler
só as pastas correspondentes.

**No console:**

1. No [Amazon S3](https://console.aws.amazon.com/s3/), crie o bucket de results
   (**Create bucket**, nome `gdbd-lab04-results-seunome-1234`, região
   `us-east-1`). Se você já configurou um local de resultados no Lab 03 e ele
   ainda existe, pode reutilizá-lo.
2. No [Amazon Athena](https://console.aws.amazon.com/athena/) > **Query editor**,
   abra **Settings > Manage** e, em **Location of query result**, informe
   `s3://SEU-RESULTS-BUCKET/`. **Save**.
3. Volte ao **Editor**. Em **Database**, escolha `futebol_part`, cole a consulta
   abaixo (troque `tabela` pelo nome que o Crawler criou, se for outro) e clique
   em **Run**:

   ```sql
   SELECT * FROM futebol_part.tabela WHERE year='2024' AND month='08';
   ```

4. Anote o **Data scanned** exibido abaixo do resultado.

**Como saber que deu certo:** a consulta termina em **Completed**, retorna só os
jogos de agosto de 2024 e mostra um **Data scanned** pequeno.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws s3 mb "s3://$RESULTS_BUCKET" --region "$REGION"
export OUTPUT="s3://$RESULTS_BUCKET/"
TABELA=$(aws glue get-tables --database-name "$DB" \
  --query 'TableList[0].Name' --output text)

QID=$(aws athena start-query-execution \
  --query-string "SELECT * FROM $DB.$TABELA WHERE year='2024' AND month='08';" \
  --query-execution-context "Database=$DB" \
  --result-configuration "OutputLocation=$OUTPUT" \
  --region "$REGION" --query 'QueryExecutionId' --output text)

# confirme SUCCEEDED antes de ler o scan (se ainda estiver RUNNING, repita)
aws athena get-query-execution --query-execution-id "$QID" \
  --query 'QueryExecution.[Status.State,Statistics.DataScannedInBytes]'
```

</details>

## 6. Comparar SEM filtro

**Porquê:** provar a diferença. A consulta sem `WHERE` de partição escaneia tudo.

**No console:**

1. No **Query editor** do Athena, rode a consulta sem filtro:

   ```sql
   SELECT * FROM futebol_part.tabela;
   ```

2. Compare o **Data scanned** com o da consulta do passo 5.

**Como saber que deu certo:** o **Data scanned** COM filtro é menor que o SEM
filtro (medido na fonte real: ~1,4 KB com filtro × ~19,6 KB sem).

> Dica: o "Data scanned" aparece embaixo de cada resultado, o que torna a
> comparação visual.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
QID2=$(aws athena start-query-execution \
  --query-string "SELECT * FROM $DB.$TABELA;" \
  --query-execution-context "Database=$DB" \
  --result-configuration "OutputLocation=$OUTPUT" \
  --region "$REGION" --query 'QueryExecutionId' --output text)

# confirme SUCCEEDED antes de ler o scan (null = ainda rodando; repita)
aws athena get-query-execution --query-execution-id "$QID2" \
  --query 'QueryExecution.[Status.State,Statistics.DataScannedInBytes]'
# compare os dois DataScannedInBytes: o COM filtro deve ser menor
# (medido na fonte real: ~1,4 KB com filtro x ~19,6 KB sem)
```

</details>

## Plano B — tabela particionada sem Crawler (Athena DDL)

**Quando usar:** se a conta não pode criar Crawler (`Account ... is denied
access`). O conceito é o mesmo: a tabela aponta para a **raiz** e as pastas
`year=/month=` viram colunas. A diferença é que você declara o esquema e pede ao
Athena para descobrir as partições (`MSCK REPAIR TABLE`), em vez do Crawler.

Rode no **Query editor** do [Amazon Athena](https://console.aws.amazon.com/athena/)
(ou via `start-query-execution`, como no passo 5), trocando `SEU-BUCKET`. Rode
um comando por vez:

```sql
CREATE DATABASE IF NOT EXISTS futebol_part;

CREATE EXTERNAL TABLE futebol_part.tabela (
  data string, mandante string, visitante string,
  gols_mandante int, gols_visitante int
)
PARTITIONED BY (year string, month string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION 's3://SEU-BUCKET/tabela/'
TBLPROPERTIES ('skip.header.line.count'='1');

-- descobre as pastas year=/month= e registra as particoes no catalogo
MSCK REPAIR TABLE futebol_part.tabela;
```

Depois siga os passos 5 e 6 normalmente (`TABELA=tabela`). Resultado medido na
fonte real: **~1,4 KB** com filtro `year='2024' AND month='08'` contra **~19,6 KB**
sem filtro.

## Limpeza

Terminou? Apague o que criou para não gerar cobrança: siga a seção
[**Limpeza** do README deste lab](https://github.com/obernardocosta/big-data/blob/main/disciplinas/gdbd/labs/lab-04-particionamento/README.md#limpeza).

## Encontrou um problema neste lab?

Um passo não bate com o que você vê no console, um menu mudou de nome ou algo
deu erro? **Abra uma issue** e ajude a melhorar a disciplina:
[abrir issue sobre o GDBD Lab 04](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+04%5D+&labels=lab).
Diga o passo, o que esperava e o que aconteceu (um print ajuda).
