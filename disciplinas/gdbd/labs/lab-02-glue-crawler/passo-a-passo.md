# Lab 02 — Passo a passo

> Rode o `dry-run.sh` deste lab antes da aula. Ele checa credencial, região,
> usuário IAM e permissões de Glue/S3/IAM — sem criar nada que custe.

```bash
export BUCKET="gdbd-lab02-$(whoami)-$RANDOM"
export REGION="us-east-1"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
```

## 1. Preparar dados no S3

**Porquê:** o Crawler varre um caminho no S3 e infere o esquema a partir dos
arquivos que encontra. Precisamos de dados para ele descobrir.

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

# jogos reais da Premier League 2024/25 (openfootball, sem API key) -> CSV
curl -s https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json \
  | python3 -c "
import json,sys,csv
dados=json.load(sys.stdin); w=csv.writer(sys.stdout)
w.writerow(['data','mandante','visitante','gols_mandante','gols_visitante'])
for m in dados['matches']:
    ft=(m.get('score') or {}).get('ft') or [None,None]
    w.writerow([m.get('date'),m.get('team1'),m.get('team2'),ft[0],ft[1]])
" > jogos.csv

aws s3 cp jogos.csv "s3://$BUCKET/jogos/jogos.csv"
```

## 2. Criar a IAM Role que o Glue vai assumir

**Porquê:** o Crawler roda **em nome da sua conta** para ler o S3 e escrever no
catálogo. Ele precisa de uma role com essa permissão (o Glue "assume" a role).

```bash
cat > trust.json <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "glue.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
JSON

aws iam create-role --role-name GlueCrawlerLabRole \
  --assume-role-policy-document file://trust.json

aws iam attach-role-policy --role-name GlueCrawlerLabRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole

# permissão de leitura no bucket do lab
aws iam attach-role-policy --role-name GlueCrawlerLabRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

## 3. Criar o banco de dados de destino

**Porquê:** o Crawler precisa saber em qual *database* do catálogo criar as
tabelas que descobrir.

```bash
aws glue create-database --database-input '{"Name":"futebol_auto"}'
```

## 4. Criar o Crawler

**Porquê:** aqui definimos o alvo (o caminho S3) e para onde vão as tabelas.
Note que apontamos para a **pasta** `jogos/`, não para o arquivo.

```bash
aws glue create-crawler \
  --name crawler-jogos \
  --role "arn:aws:iam::$ACCOUNT_ID:role/GlueCrawlerLabRole" \
  --database-name futebol_auto \
  --targets '{"S3Targets":[{"Path":"s3://'"$BUCKET"'/jogos/"}]}'
```

## 5. Rodar o Crawler e ver a tabela nascer

**Porquê:** este é o ponto do lab — o esquema é **inferido**, você não digitou
coluna nenhuma.

```bash
aws glue start-crawler --name crawler-jogos

# acompanhe o estado (RUNNING -> STOPPING -> READY)
aws glue get-crawler --name crawler-jogos --query 'Crawler.State'

# quando READY, veja a tabela criada automaticamente
aws glue get-tables --database-name futebol_auto \
  --query 'TableList[].{Nome:Name,Colunas:StorageDescriptor.Columns[].Name}'
```

## 6. Atualização automática de esquema

**Porquê:** o diferencial do Crawler é manter o catálogo em dia. Adicione um
arquivo com uma coluna nova e rode de novo.

```bash
# novo arquivo na MESMA pasta, com uma coluna a mais (rodada)
curl -s https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json \
  | python3 -c "
import json,sys,csv
dados=json.load(sys.stdin); w=csv.writer(sys.stdout)
w.writerow(['data','mandante','visitante','gols_mandante','gols_visitante','rodada'])
for m in dados['matches'][:20]:
    ft=(m.get('score') or {}).get('ft') or [None,None]
    w.writerow([m.get('date'),m.get('team1'),m.get('team2'),ft[0],ft[1],m.get('round')])
" > jogos_v2.csv

aws s3 cp jogos_v2.csv "s3://$BUCKET/jogos/jogos_v2.csv"

aws glue start-crawler --name crawler-jogos
# aguarde READY e inspecione as colunas de novo — a coluna "rodada" deve aparecer
```

## Limpeza

Veja a seção "Limpeza" do `README.md`.
