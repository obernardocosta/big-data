# Lab 04 — Passo a passo

> Rode o `dry-run.sh` deste lab antes da aula. Ele checa credencial, região,
> usuário IAM e permissões de S3/Glue/Athena/IAM — tudo read-only, sem custo.

```bash
export BUCKET="gdbd-lab04-$(whoami)-$RANDOM"
export REGION="us-east-1"
export RESULTS_BUCKET="gdbd-lab04-results-$(whoami)-$RANDOM"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export DB="futebol_part"
```

## 1. Criar o bucket e subir dados JÁ PARTICIONADOS

**Porquê:** a partição é o **nome da pasta**. O Athena vai tratar `year`, `month`
e `day` como colunas só porque os arquivos estão organizados assim. A separação
dos dados nas partições é feita por nós (manual neste lab).

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

# Jogos reais (openfootball 2024/25) particionados por ano/mês a partir da DATA
# real de cada partida. Um Python curto lê o JSON e grava um CSV por partição.
curl -s https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json \
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

## 2. Reaproveitar a role de serviço do Glue

**Porquê:** o Crawler precisa de uma role para ler o S3 e escrever no catálogo —
a mesma lógica do Lab 02. Se já criou a `GlueCrawlerLabRole` lá, reutilize.

```bash
aws iam get-role --role-name GlueCrawlerLabRole >/dev/null 2>&1 \
  && echo "role ja existe" \
  || echo "crie a role como no Lab 02 (passo 2) antes de continuar"
```

## 3. Criar o database e o Crawler apontando para a RAIZ da tabela

**Porquê:** apontamos para `s3://.../tabela/` (a raiz), **não** para uma partição
específica. É assim que o Crawler enxerga a estrutura `year/month/day` e a
registra como colunas de partição.

```bash
aws glue create-database --database-input "{\"Name\":\"$DB\"}"

aws glue create-crawler \
  --name crawler-particionado \
  --role "arn:aws:iam::$ACCOUNT_ID:role/GlueCrawlerLabRole" \
  --database-name "$DB" \
  --targets "{\"S3Targets\":[{\"Path\":\"s3://$BUCKET/tabela/\"}]}"
```

## 4. Rodar o Crawler e conferir as colunas de partição

**Porquê:** aqui confirmamos que `year` e `month` viraram **partitionKeys**
da tabela — é o que habilita o filtro otimizado no Athena.

```bash
aws glue start-crawler --name crawler-particionado
aws glue get-crawler --name crawler-particionado --query 'Crawler.State'

# quando READY, veja as chaves de particao
aws glue get-tables --database-name "$DB" \
  --query 'TableList[].{Nome:Name,Particoes:PartitionKeys[].Name}'
```

## 5. Consultar COM filtro de partição e medir o scan

**Porquê:** este é o ponto do lab. Filtrar por `year/month` faz o Athena ler
só as pastas correspondentes.

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

aws athena get-query-execution --query-execution-id "$QID" \
  --query 'QueryExecution.Statistics.DataScannedInBytes'
```

## 6. Comparar SEM filtro

**Porquê:** provar a diferença. A consulta sem `WHERE` de partição escaneia tudo.

```bash
QID2=$(aws athena start-query-execution \
  --query-string "SELECT * FROM $DB.$TABELA;" \
  --query-execution-context "Database=$DB" \
  --result-configuration "OutputLocation=$OUTPUT" \
  --region "$REGION" --query 'QueryExecutionId' --output text)

aws athena get-query-execution --query-execution-id "$QID2" \
  --query 'QueryExecution.Statistics.DataScannedInBytes'
# compare os dois DataScannedInBytes: o COM filtro deve ser menor
```

> Dica: no console do Athena o "Data scanned" aparece embaixo de cada resultado,
> o que torna a comparação visual e boa para demonstrar ao vivo.

## Limpeza

Veja a seção "Limpeza" do `README.md`.
