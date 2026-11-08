# Lab 02 — Passo a passo

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

Defina as variáveis do lab. Se for usar o terminal ou o CloudShell, rode também:

```bash
export BUCKET="gdbd-lab02-$(whoami)-$RANDOM"
export REGION="us-east-1"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
echo "$BUCKET"   # anote este nome: você vai usá-lo nos passos seguintes
```

## 1. Preparar dados no S3

**Porquê:** o Crawler varre um caminho no S3 e infere o esquema a partir dos
arquivos que encontra. Precisamos de dados para ele descobrir.

Este passo é **preparação**, não conceito do lab: converter o JSON em CSV não
tem um equivalente simples no console. Por isso aqui o **script é o caminho
principal**. Rode no terminal ou no [AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1)
(terminal no navegador, já com a AWS CLI e o Python). O script também cria o
bucket:

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

# jogos reais da Premier League 2024/25 (openfootball, cópia no repo data) -> CSV
curl -s https://raw.githubusercontent.com/obernardocosta/data/main/football/premier-league/2024-25/en.1.json \
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

**Como saber que deu certo:** no [Amazon S3](https://console.aws.amazon.com/s3/),
abra o seu bucket > pasta `jogos/` e veja o arquivo `jogos.csv`.

## 2. Criar a IAM Role que o Glue vai assumir

**Porquê:** o Crawler roda **em nome da sua conta** para ler o S3 e escrever no
catálogo. Ele precisa de uma role com essa permissão (o Glue "assume" a role).

**No console:**

1. Abra o [IAM](https://console.aws.amazon.com/iam/) e, no menu lateral, vá em
   **Roles > Create role**.
2. Em **Trusted entity type**, escolha **AWS service**. Em **Use case**, escolha
   **Glue** (a *trust policy* passa a permitir `glue.amazonaws.com`). Avance.
3. Em **Add permissions**, procure e marque as duas políticas:
   `AWSGlueServiceRole` e `AmazonS3ReadOnlyAccess`. Avance.
4. Em **Role name**, digite `GlueCrawlerLabRole` e clique em **Create role**.

**Como saber que deu certo:** a role `GlueCrawlerLabRole` aparece em **Roles**,
com as duas políticas na aba **Permissions**.

**Dica:** role recém-criada leva alguns segundos para propagar no IAM. Se o
Crawler reclamar de "unable to assume role", espere um pouco e tente de novo.
É o mesmo comportamento que você vai ver em qualquer serviço da AWS.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

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

# Role recem-criada leva alguns segundos para propagar no IAM. Sem esta pausa o
# create-crawler responde "Service is unable to assume provided role" (visto no
# teste real). E o mesmo comportamento que voce vai ver em todo servico da AWS.
sleep 15
```

</details>

## 3. Criar o banco de dados de destino

**Porquê:** o Crawler precisa saber em qual *database* do catálogo criar as
tabelas que descobrir.

**No console:**

1. Abra o [AWS Glue](https://console.aws.amazon.com/glue/) e, no menu lateral, vá em
   **Data Catalog > Databases**.
2. Clique em **Add database**.
3. Em **Name**, digite `futebol_auto` e clique em **Create database**.

**Como saber que deu certo:** o database `futebol_auto` aparece na lista.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws glue create-database --database-input '{"Name":"futebol_auto"}'
```

</details>

## 4. Criar o Crawler

**Porquê:** aqui definimos o alvo (o caminho S3) e para onde vão as tabelas.
Note que apontamos para a **pasta** `jogos/`, não para o arquivo.

**No console:**

1. No [AWS Glue](https://console.aws.amazon.com/glue/), vá em **Data Catalog >
   Crawlers** (ou **Crawlers**, dependendo da versão do console) e clique em
   **Create crawler**.
2. **Name:** `crawler-jogos`. Avance.
3. Em **Data sources**, clique em **Add a data source**: **Data source:** S3 ·
   **S3 path:** a **pasta** `s3://SEU-BUCKET/jogos/` (use **Browse S3** se
   preferir) · deixe o restante como padrão e clique em **Add an S3 data source**.
   Avance.
4. Em **IAM role**, escolha a `GlueCrawlerLabRole` criada no passo 2. Avance.
5. Em **Target database**, escolha `futebol_auto`. Em **Crawler schedule**
   (**Frequency**), deixe **On demand**. Avance.
6. Revise e clique em **Create crawler**.

**Como saber que deu certo:** o `crawler-jogos` aparece na lista de crawlers com
estado **Ready**.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws glue create-crawler \
  --name crawler-jogos \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/GlueCrawlerLabRole" \
  --database-name futebol_auto \
  --targets '{"S3Targets":[{"Path":"s3://'"$BUCKET"'/jogos/"}]}'
```

</details>

## 5. Rodar o Crawler e ver a tabela nascer

**Porquê:** este é o ponto do lab — o esquema é **inferido**, você não digitou
coluna nenhuma.

**No console:**

1. Em **Crawlers**, selecione `crawler-jogos` e clique em **Run** (ou **Run
   crawler**).
2. Acompanhe a coluna **State**: **Starting/Running** > **Stopping** > **Ready**.
   Clique no ícone de atualizar. Leva de segundos a ~2 min.
3. Quando voltar a **Ready**, vá em **Data Catalog > Tables**, abra a tabela
   criada (`jogos`, nome da pasta) e olhe o **Schema**.

**Como saber que deu certo:** a tabela `jogos` existe no database `futebol_auto`
e o Schema mostra as 5 colunas (`data`, `mandante`, `visitante`,
`gols_mandante`, `gols_visitante`) que você **não digitou**.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws glue start-crawler --name crawler-jogos

# acompanhe o estado (RUNNING -> STOPPING -> READY)
aws glue get-crawler --name crawler-jogos --query 'Crawler.State'

# quando READY, veja a tabela criada automaticamente
aws glue get-tables --database-name futebol_auto \
  --query 'TableList[].{Nome:Name,Colunas:StorageDescriptor.Columns[].Name}'
```

</details>

## 6. Atualização automática de esquema

**Porquê:** o diferencial do Crawler é manter o catálogo em dia. Adicione um
arquivo com uma coluna nova e rode de novo.

Gerar o segundo CSV é, de novo, **preparação** sem equivalente simples no
console. O **script é o caminho principal** para criar e enviar o arquivo
(terminal ou [AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1)):

```bash
# novo arquivo na MESMA pasta, com uma coluna a mais (rodada)
curl -s https://raw.githubusercontent.com/obernardocosta/data/main/football/premier-league/2024-25/en.1.json \
  | python3 -c "
import json,sys,csv
dados=json.load(sys.stdin); w=csv.writer(sys.stdout)
w.writerow(['data','mandante','visitante','gols_mandante','gols_visitante','rodada'])
for m in dados['matches'][:20]:
    ft=(m.get('score') or {}).get('ft') or [None,None]
    w.writerow([m.get('date'),m.get('team1'),m.get('team2'),ft[0],ft[1],m.get('round')])
" > jogos_v2.csv

aws s3 cp jogos_v2.csv "s3://$BUCKET/jogos/jogos_v2.csv"
```

**No console:**

1. No S3, confirme que `jogos_v2.csv` está na **mesma pasta** `jogos/`.
2. No [AWS Glue](https://console.aws.amazon.com/glue/), em **Crawlers**,
   selecione `crawler-jogos` e clique em **Run** de novo. Aguarde **Ready**.
3. Abra a tabela `jogos` (**Data Catalog > Tables**) e olhe o **Schema**.

**Como saber que deu certo:** a coluna `rodada` apareceu na tabela, sem você
editar nada. O Crawler atualizou o catálogo sozinho.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws glue start-crawler --name crawler-jogos
# aguarde READY e inspecione as colunas de novo — a coluna "rodada" deve aparecer
```

</details>

## Limpeza

Terminou? Apague o que criou para não gerar cobrança: siga a seção
[**Limpeza** do README deste lab](https://github.com/obernardocosta/big-data/blob/main/disciplinas/gdbd/labs/lab-02-glue-crawler/README.md#limpeza).

## Encontrou um problema neste lab?

Um passo não bate com o que você vê no console, um menu mudou de nome ou algo
deu erro? **Abra uma issue** e ajude a melhorar a disciplina:
[abrir issue sobre o GDBD Lab 02](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+02%5D+&labels=lab).
Diga o passo, o que esperava e o que aconteceu (um print ajuda).
