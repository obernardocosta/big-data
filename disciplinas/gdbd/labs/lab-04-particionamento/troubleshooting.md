# Lab 04 — Troubleshooting

Erros comuns e como resolver. Rode o `dry-run.sh` deste lab primeiro: ele aponta
a maioria destes problemas antes da aula.

## As colunas de partição (year/month/day) não apareceram

- Causa mais comum: o Crawler aponta para uma **partição específica** em vez da
  **raiz** da tabela. O alvo deve ser `s3://SEU-BUCKET/tabela/`, não
  `.../tabela/year=2022/`.
- As pastas precisam seguir o formato `chave=valor` (ex.: `year=2022`). Sem o
  `=`, o Crawler não reconhece como partição.
- Confirme: `aws glue get-table --database-name futebol_part --name <TABELA>
  --query 'Table.PartitionKeys'`.

## O "Data scanned" com filtro não ficou menor

- Com pouquíssimos dados (poucos KB), o Athena pode ler um mínimo e a diferença
  fica pequena ou nula. Para demonstrar bem, use mais partições/arquivos.
- Confirme que o `WHERE` usa exatamente os nomes das colunas de partição
  (`year`, `month`, `day`) e que os valores batem com os nomes das pastas
  (string: `year='2022'`).

## "The specified role cannot be assumed by Glue" / role ausente

- Reutilize a `GlueCrawlerLabRole` do Lab 02 ou recrie-a (Lab 02, passo 2). A
  trust policy precisa permitir `glue.amazonaws.com` e a role precisa de leitura
  no bucket. Recém-criada, pode levar segundos para propagar.

## "No output location provided" no Athena

- O Athena grava resultados no S3. Crie o bucket de results e passe
  `--result-configuration OutputLocation=s3://.../` (passo 5).

## "AccessDenied"

- O lab toca em quatro serviços: o usuário precisa de permissões de **S3**
  (ler/escrever no bucket do lab e no de results), **Glue** (Crawler + catálogo),
  **Athena** (executar queries) e **IAM** (criar/usar a role de serviço, incluindo
  `iam:PassRole`).

## O Crawler fica "RUNNING" e não termina

- Rodadas sobre poucos arquivos levam segundos a ~1-2 min
  (RUNNING → STOPPING → READY). Se travar, pare com
  `aws glue stop-crawler --name crawler-particionado` e verifique a role.

## A região "não tem" meu recurso

- Bucket, tabela, Crawler e consulta precisam estar na **mesma região**.
  Padronize: `export AWS_REGION=us-east-1`.

## Plano B — serviço indisponível na região

Se Glue ou Athena estiverem instáveis na região da turma:

1. Troque a região (`us-east-1`, `us-east-2`, `sa-east-1`) e rode o `dry-run.sh`
   de novo.
2. Se persistir, conduza o lab como **demonstração** a partir de uma saída já
   capturada (inclusive a comparação de "Data scanned"). Não gaste tempo de aula
   subindo ambiente — essa é a lição da preparação prévia.
