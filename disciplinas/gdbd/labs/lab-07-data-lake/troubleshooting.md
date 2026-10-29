# Lab 07 — Troubleshooting

Erros comuns e como resolver. Rode o `dry-run.sh` deste lab primeiro — ele valida
o ambiente sem rodar o Glue Job (o único passo com custo relevante).

## O Glue Job (raw → clean) falha com "AccessDenied" no S3

- A **role do Glue** precisa de **leitura** em `raw/` e **escrita** em `clean/`.
  O `AmazonS3ReadOnlyAccess` não basta — adicione escrita no bucket do lab.
- Lembre do `iam:PassRole`: sem ele, criar/rodar o Job falha.

## O Crawler não cria a tabela da camada Clean

- Aponte o Crawler para a **pasta** `s3://SEU-BUCKET/clean/premier/` (com barra),
  não para um arquivo. Confirme que o Job gravou o Parquet lá antes de rodar o
  Crawler.

## O CTAS da camada Specialized falha

- **"external_location already exists"**: o Athena exige um caminho **vazio**
  para CTAS. Use um prefixo novo em `specialized/` ou limpe o anterior:
  `aws s3 rm s3://SEU-BUCKET/specialized/gols_por_time/ --recursive`.
- **Sem bucket de query results**: configure o local de resultados do Athena
  (como no Lab 03) antes do CTAS.
- **Tipos**: `fthg`/`ftag` podem vir como string do CSV; use `CAST(... AS integer)`
  (o passo a passo já faz isso).

## Confundi as camadas / dado "sumiu"

- A camada **Raw é imutável**: nunca escreva por cima dela. Se algo deu errado em
  Clean/Specialized, **reprocesse a partir da Raw** — é justamente a vantagem do
  modelo em camadas.

## "Database already exists" / "Table already exists"

- Reexecução do lab. Apague o que já existe (ver Limpeza no README) ou use nomes
  novos para database/tabelas.

## A região "não tem" meu recurso

- Bucket, database, Job, Crawler e Athena precisam estar na **mesma região**.
  Padronize: `export AWS_REGION=us-east-1`.

## Plano B — sem orçamento para o Glue Job

Se a turma não puder gerar custo com o Job de transformação:

1. Monte a camada **Clean** manualmente (suba um Parquet já convertido) e siga
   do passo 4 (Crawler) em diante — assim o custo some.
2. Ou conduza como **demonstração** a partir de um bucket já montado,
   percorrendo Raw → Clean → Specialized e o mapa mental das aulas.

O objetivo (entender a arquitetura em camadas e onde cada serviço entra) é
alcançado mesmo sem rodar o Job ao vivo.
