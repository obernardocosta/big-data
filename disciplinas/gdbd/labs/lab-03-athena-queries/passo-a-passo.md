# Lab 03 — Passo a passo

> Rode o `dry-run.sh` deste lab antes da aula. Ele checa credencial, região,
> usuário IAM, se existe uma tabela catalogada e as permissões de Athena/Glue/S3
> — tudo read-only, sem custo.

```bash
export REGION="us-east-1"
export RESULTS_BUCKET="gdbd-lab03-results-$(whoami)-$RANDOM"
export DB="futebol"   # o database criado no Lab 01 (ou 'futebol_auto' do Lab 02)
```

## 1. Criar o bucket de query results

**Porquê:** o Athena **grava o resultado de cada consulta no S3**. Sem um local
de resultados configurado, a primeira query falha. Esse bucket é separado do
bucket de dados.

```bash
aws s3 mb "s3://$RESULTS_BUCKET" --region "$REGION"
```

## 2. Conferir que a tabela existe no catálogo

**Porquê:** o Athena não guarda esquema próprio — ele lê o **Glue Data Catalog**.
Se a tabela do Lab 01/02 não estiver lá, não há o que consultar.

```bash
aws glue get-tables --database-name "$DB" \
  --query 'TableList[].Name'
```

## 3. Apontar o Athena para o bucket de resultados

**Porquê:** definimos onde os resultados vão. Aqui usamos o parâmetro
`--result-configuration` a cada consulta (também dá para configurar um workgroup
uma vez só).

```bash
export OUTPUT="s3://$RESULTS_BUCKET/"
```

## 4. Primeira consulta — top 10 jogadores

**Porquê:** este é o ponto do lab — SQL distribuído sobre arquivos no S3, sem
servidor. Ajuste o nome da tabela/colunas ao que o seu catálogo tem.

```bash
QID=$(aws athena start-query-execution \
  --query-string "SELECT jogador, SUM(premios) AS total
                  FROM $DB.melhores_jogadores
                  GROUP BY jogador ORDER BY total DESC LIMIT 10;" \
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

**Observe o "Data scanned":**

```bash
aws athena get-query-execution --query-execution-id "$QID" \
  --query 'QueryExecution.Statistics.DataScannedInBytes'
```

Esse número é o que o Athena cobra (US$ 5/TB). Guarde-o — no Lab 04 ele cai com
partição.

## 5. Demais perguntas de negócio

**Porquê:** mostram que, uma vez catalogado, o dado responde SQL comum. Troque a
`--query-string` das consultas acima por:

```sql
-- País com mais ganhadores e total de prêmios
SELECT pais, COUNT(*) AS ganhadores, SUM(premios) AS premios
FROM futebol.melhores_jogadores
GROUP BY pais ORDER BY premios DESC;

-- (Premier League 18/19, se a tabela estiver catalogada)
-- Time que mais marcou gols em casa
SELECT hometeam AS time, SUM(fthg) AS gols_casa
FROM futebol.premier_1819
GROUP BY hometeam ORDER BY gols_casa DESC LIMIT 1;

-- Maior goleada da temporada
SELECT date, hometeam, awayteam, ABS(fthg - ftag) AS diferenca
FROM futebol.premier_1819
ORDER BY diferenca DESC LIMIT 1;
```

## Dica: console web

No Console do Athena dá para rodar tudo isso no editor de queries e ver o
"Data scanned" e o tempo embaixo de cada resultado — útil para demonstrar ao vivo.

## Limpeza

Veja a seção "Limpeza" do `README.md`.
