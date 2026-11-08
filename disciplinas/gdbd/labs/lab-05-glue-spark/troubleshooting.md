# Lab 05 — Troubleshooting

Erros comuns e como resolver. Não achou o seu caso aqui? [Abra uma issue](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+05%5D+&labels=lab)
com o passo, o erro e um print.

## "Account <id> is denied access" ao criar Crawler ou Glue Job

- **Não é permissão IAM.** É um bloqueio no nível da conta, comum em contas
  novas: acontece mesmo com `AdministratorAccess`, e o Glue Data Catalog
  (`create-database`, `create-table`) continua funcionando. Visto no teste real
  de 2026-11-08 em `us-east-1`.
- **Como resolver:** abra um caso no **AWS Support → Account and billing**
  (gratuito, sem plano pago), pedindo a liberação do AWS Glue (Crawler e Jobs)
  na região do lab. Pode levar de horas a dias: peça na primeira semana de aula.
- **Enquanto isso:** o mesmo PySpark roda no **EMR Serverless** (Lab A da PDN, testado) ou num step do EMR (Lab 06, testado), trocando só o `GlueContext` por `SparkSession`.

## O Job falha com "AccessDenied" ao ler/escrever no S3

- A **role do Glue** (não o seu usuário) é quem acessa o S3 durante o Job.
  Garanta que a `GlueCrawlerLabRole` tem leitura em `raw/` e **escrita** em
  `parquet/`. O `AmazonS3ReadOnlyAccess` do Lab 02 **não basta** aqui (precisa
  escrever). Adicione escrita no bucket do lab.

## "User is not authorized to perform: iam:PassRole"

- Para criar/rodar o Job você precisa de `iam:PassRole` sobre a role do Glue.
  Sem isso, o `create-job`/`start-job-run` falha mesmo com a role existindo.

## O Job fica em "RUNNING" muito tempo / demora para começar

- Glue Job tem um tempo de **cold start** (provisiona o ambiente Spark) de ~1 min
  antes de processar. Em datasets minúsculos, a maior parte do tempo é startup.
  Acompanhe: `aws glue get-job-run --job-name <job> --run-id <id>
  --query 'JobRun.JobRunState'`.

## "JobRunState: FAILED" — como ver o erro

- Veja a mensagem de erro do run:
  `aws glue get-job-run --job-name <job> --run-id <id>
   --query 'JobRun.ErrorMessage'`.
- Logs detalhados ficam no CloudWatch (`/aws-glue/jobs/output` e `/error`).

## "Cannot resolve column" / colunas erradas no Parquet

- Os nomes das colunas no `.select(...)` precisam bater com o cabeçalho do CSV
  (`header=True`). Confira o CSV de entrada; maiúsculas/minúsculas importam.

## O Parquet não aparece em `parquet/`

- Confirme que o `--OUTPUT` aponta para `s3://SEU-BUCKET/parquet/` e que o Job
  terminou em `SUCCEEDED`. O Spark grava arquivos `part-...snappy/gzip.parquet`
  mais um `_SUCCESS`.

## Esqueci de limpar e tenho medo de cobrança

- Glue cobra só pelo **tempo de execução** do Job; um job que não roda não
  acumula custo. Mesmo assim, apague o Job e o bucket na Limpeza e confira que
  **não há agendamento/trigger** criado.

## Plano B — Glue indisponível ou sem orçamento para rodar

1. Troque a região e tente de novo.
2. Se a turma não puder gerar custo, conduza como **demonstração**: mostre o
   script PySpark, explique DPU/preço e use um Parquet já gerado para as
   consultas no Athena. O conceito (Spark serverless + formato colunar) é
   aprendido mesmo sem executar o Job ao vivo.
