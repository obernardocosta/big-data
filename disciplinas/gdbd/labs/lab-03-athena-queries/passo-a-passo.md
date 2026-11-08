# Lab 03 — Passo a passo

> **Como usar este roteiro**
>
> 1. Assista à **demo ao vivo** do instrutor (ele faz os passos 3 e 4 uma vez).
> 2. Repita você mesmo **no console da AWS**, seguindo as instruções de cada passo.
> 3. Travou ou está sem tempo? Cada passo tem um bloco **"Prefere o terminal?"**
>    (recolhido) com o mesmo passo em **AWS CLI**. Clique para abrir.

**Console da AWS:** <https://console.aws.amazon.com/> · região **N. Virginia
(`us-east-1`)**, confira no canto superior direito.

Defina as variáveis do lab. Se for usar o terminal ou o CloudShell, rode também:

```bash
export REGION="us-east-1"
export RESULTS_BUCKET="gdbd-lab03-results-$(whoami)-$RANDOM"
export DB="futebol"   # o database criado no Lab 01 (ou 'futebol_auto' do Lab 02)
echo "$RESULTS_BUCKET"   # anote este nome: você vai usá-lo nos passos seguintes
```

## 1. Criar o bucket de query results

**Porquê:** o Athena **grava o resultado de cada consulta no S3**. Sem um local
de resultados configurado, a primeira query falha. Esse bucket é separado do
bucket de dados.

**No console:**

1. Abra o [Amazon S3](https://console.aws.amazon.com/s3/) e clique em **Create bucket**.
2. Em **Bucket name**, use o nome que você anotou (ex.: `gdbd-lab03-results-seunome-1234`).
3. Em **AWS Region**, confirme `US East (N. Virginia) us-east-1`.
4. Deixe o restante como padrão e clique em **Create bucket**.

**Como saber que deu certo:** o bucket aparece na lista de buckets do S3.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws s3 mb "s3://$RESULTS_BUCKET" --region "$REGION"
```

</details>

## 2. Conferir que a tabela existe no catálogo

**Porquê:** o Athena não guarda esquema próprio — ele lê o **Glue Data Catalog**.
Se a tabela do Lab 01/02 não estiver lá, não há o que consultar.

**No console:**

1. Abra o [AWS Glue](https://console.aws.amazon.com/glue/) e vá em **Data Catalog >
   Tables**.
2. Procure a tabela `jogos` e confira o **Database** dela: `futebol` (Lab 01) ou
   `futebol_auto` (Lab 02).

**Como saber que deu certo:** a tabela `jogos` aparece na lista, no database que
você vai usar nas consultas.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws glue get-tables --database-name "$DB" \
  --query 'TableList[].Name'
```

</details>

## 3. Apontar o Athena para o bucket de resultados

**Porquê:** definimos onde os resultados vão. No console, isso é uma
configuração do *workgroup* (uma vez só); no terminal, passamos o parâmetro
`--result-configuration` a cada consulta.

**No console:**

1. Abra o [Amazon Athena](https://console.aws.amazon.com/athena/) e vá em **Query
   editor** (ou **Launch query editor**).
2. Se aparecer o aviso para configurar o local de resultados, clique em **Edit
   settings**. Se não, abra a aba **Settings** e clique em **Manage**.
3. Em **Location of query result**, informe `s3://SEU-RESULTS-BUCKET/` (ou use
   **Browse S3**) e clique em **Save**.

**Como saber que deu certo:** em **Settings**, o campo **Location of query
result** mostra o seu bucket.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
export OUTPUT="s3://$RESULTS_BUCKET/"
```

</details>

## 4. Primeira consulta — times que mais marcam em casa

**Porquê:** este é o ponto do lab — SQL distribuído sobre arquivos no S3, sem
servidor. A tabela `jogos` foi catalogada no Lab 01/02 (dados reais 2024/25).

**No console:**

1. No **Query editor** do Athena, em **Data source** deixe `AwsDataCatalog` e, em
   **Database**, escolha `futebol` (ou `futebol_auto`).
2. Cole a consulta abaixo (ajuste o nome do database se usar o `futebol_auto`)
   e clique em **Run**:

   ```sql
   SELECT mandante, SUM(gols_mandante) AS gols_casa
   FROM futebol.jogos
   GROUP BY mandante ORDER BY gols_casa DESC LIMIT 10;
   ```

3. Olhe a área de resultado, logo abaixo: **Results**, e as métricas **Run
   time** e **Data scanned**.

**Como saber que deu certo:** a consulta termina com status **Completed** e
retorna 10 linhas, com os times que mais marcaram em casa.

**Observe o "Data scanned":** esse número é o que o Athena cobra (US$ 5/TB).
Guarde-o — no Lab 04 ele cai com partição.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
QID=$(aws athena start-query-execution \
  --query-string "SELECT mandante, SUM(gols_mandante) AS gols_casa
                  FROM $DB.jogos
                  GROUP BY mandante ORDER BY gols_casa DESC LIMIT 10;" \
  --query-execution-context "Database=$DB" \
  --result-configuration "OutputLocation=$OUTPUT" \
  --region "$REGION" --query 'QueryExecutionId' --output text)

# acompanhe até SUCCEEDED
aws athena get-query-execution --query-execution-id "$QID" \
  --query 'QueryExecution.Status.State'

# veja o resultado
aws athena get-query-results --query-execution-id "$QID" \
  --query 'ResultSet.Rows'
```

Para ver o "Data scanned":

```bash
aws athena get-query-execution --query-execution-id "$QID" \
  --query 'QueryExecution.Statistics.DataScannedInBytes'
```

</details>

## 5. Demais perguntas de negócio

**Porquê:** mostram que, uma vez catalogado, o dado responde SQL comum.

Este passo é só SQL, então o **editor de consultas é o caminho principal**. No
**Query editor** do Athena, apague a consulta anterior, cole cada uma abaixo e
clique em **Run** (no terminal, é só trocar a `--query-string` da consulta do
passo 4):

```sql
-- Total de gols por rodada. So existe na tabela do Lab 02 (database
-- futebol_auto), onde o Crawler descobriu a coluna 'rodada'. Na tabela do
-- Lab 01 (futebol.jogos) essa coluna nao existe e a query falha.
-- Resultado esperado: so 'Matchday 1' e 'Matchday 2'. Apenas os 20 jogos do
-- arquivo novo (jogos_v2.csv) trazem a rodada; nos 380 do arquivo antigo ela
-- vem NULL. E o Schema Evolution na pratica: o esquema mudou, os dados
-- antigos nao.
SELECT rodada, SUM(gols_mandante + gols_visitante) AS gols
FROM futebol_auto.jogos
WHERE rodada IS NOT NULL
GROUP BY rodada ORDER BY gols DESC;

-- Maior goleada da temporada (diferença de gols)
SELECT data, mandante, visitante, ABS(gols_mandante - gols_visitante) AS diferenca
FROM futebol.jogos
ORDER BY diferenca DESC LIMIT 1;

-- Jogos com mais gols no total
SELECT data, mandante, visitante, (gols_mandante + gols_visitante) AS total_gols
FROM futebol.jogos
ORDER BY total_gols DESC LIMIT 5;
```

**Como saber que deu certo:** cada consulta termina em **Completed** e mostra o
resultado. Compare o **Data scanned** de cada uma com o da primeira.

## Limpeza

Terminou? Apague o que criou para não gerar cobrança: siga a seção
[**Limpeza** do README deste lab](https://github.com/obernardocosta/big-data/blob/main/disciplinas/gdbd/labs/lab-03-athena-queries/README.md#limpeza).

## Encontrou um problema neste lab?

Um passo não bate com o que você vê no console, um menu mudou de nome ou algo
deu erro? **Abra uma issue** e ajude a melhorar a disciplina:
[abrir issue sobre o GDBD Lab 03](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+03%5D+&labels=lab).
Diga o passo, o que esperava e o que aconteceu (um print ajuda).
