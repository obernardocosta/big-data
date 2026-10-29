# Lab 01 (PDN) — Troubleshooting

Erros comuns e como resolver. Rode o `dry-run.sh` primeiro — ele valida o
ambiente sem criar Application nem submeter job (o job é o que gera custo).

## "is not authorized to perform: iam:PassRole" ao submeter o job

- Para submeter um job com uma **RuntimeRole**, seu usuário precisa de
  `iam:PassRole` sobre essa role. É o erro mais comum do EMR Serverless.

## O job falha com "AccessDenied" lendo o script ou gravando a saída

- A **RuntimeRole** (não o seu usuário) acessa o S3 durante o job. Garanta que
  ela tem leitura em `scripts/` e **escrita** em `out/`. No lab usamos
  `AmazonS3FullAccess`; em produção, restrinja ao bucket.

## "The specified role cannot be assumed by EMR Serverless"

- A trust policy da RuntimeRole precisa permitir o principal
  `emr-serverless.amazonaws.com`. Confira o `trust-emrs.json` do passo 2.

## O job fica em "PENDING"/"SCHEDULED" antes de rodar

- Normal: a Application aloca capacidade sob demanda. Em jobs pequenos, boa parte
  do tempo é esse provisionamento. Acompanhe com
  `aws emr-serverless get-job-run --application-id <APP> --job-run-id <ID>
   --query 'jobRun.state'`.

## O job falha por falta de uma lib Python

- É o ponto do passo 6. Empacote as dependências (virtualenv + `venv-pack`) e
  referencie via `--archives`/`spark.archives`, ou use `--py-files`. Siga o
  exemplo **Python Dependencies** em `emr-serverless-samples`.

## "ValidationException: release label"

- Use um `--release-label` válido (ex.: `emr-7.1.0`). Versões muito antigas ou
  inexistentes são recusadas. Consulte as versões disponíveis na região.

## Como ver os logs do job

- Configure um destino de logs (S3/CloudWatch) na Application ou no job run, e
  veja `stdout`/`stderr` do driver lá. Sem destino de log, o diagnóstico fica
  limitado ao `stateDetails` do `get-job-run`.

## Tenho medo de custo esquecido

- O EMR Serverless **não deixa cluster ocioso cobrando** — a cobrança é por
  recurso **durante o job**. Ainda assim, apague a Application e o bucket na
  limpeza. Confira: `aws emr-serverless list-applications`.

## Plano B — EMR Serverless indisponível ou sem orçamento

1. Troque a região e rode o `dry-run.sh` de novo.
2. Sem orçamento, conduza como **demonstração** a partir de um job já executado
   (mostre `get-job-run` em `SUCCESS` e a saída no S3) e os exemplos do
   repositório oficial. O conceito (Spark sem cluster + RuntimeRole por job) é
   aprendido mesmo sem submeter ao vivo.
