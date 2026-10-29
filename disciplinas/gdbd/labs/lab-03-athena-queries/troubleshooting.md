# Lab 03 — Troubleshooting

Erros comuns e como resolver. Rode o `dry-run.sh` deste lab primeiro: ele aponta
a maioria destes problemas antes da aula.

## "No output location provided" / a primeira query falha

- O Athena **precisa** de um local de resultados no S3. Crie o bucket de results
  (passo 1) e passe `--result-configuration OutputLocation=s3://.../` na consulta,
  ou configure um workgroup com local de saída.

## "Unable to locate credentials" / credencial inválida

- Rode `aws configure` e informe Access Key, Secret e região.
- Confirme com `aws sts get-caller-identity`.

## "Table ... does not exist" / "Database does not exist"

- O Athena consulta o **Glue Data Catalog**. A tabela precisa ter sido criada no
  Lab 01/02. Confirme com `aws glue get-tables --database-name <DB>`.
- Verifique se você está no **mesmo database** (`futebol` no Lab 01,
  `futebol_auto` no Lab 02) e na **mesma região** em que a tabela foi criada.

## "AccessDenied" ao rodar a consulta

- O usuário precisa de permissão de **Athena** (`athena:StartQueryExecution`,
  `GetQueryExecution`, `GetQueryResults`), de **Glue** (leitura do catálogo) e de
  **S3** (ler o bucket de dados e **escrever** no bucket de results). Faltar a
  escrita no bucket de results é a causa mais comum.

## A consulta volta vazia (0 linhas)

- Os nomes de coluna inferidos pelo Crawler podem diferir do seu SQL (ex.: o
  Crawler cria `col0, col1...` quando o CSV não tem cabeçalho). Confira as
  colunas reais: `aws glue get-table --database-name <DB> --name <TABELA>`.
- Confirme que há arquivos no caminho S3 da tabela.

## O "Data scanned" está alto para pouco dado

- Formatos linha a linha (CSV/JSON) escaneiam tudo. É esperado aqui — é
  justamente a motivação do **Lab 04** (particionamento) e, mais à frente, de
  formatos colunares (Parquet).

## A região "não tem" meu recurso

- Tabela e consulta precisam estar na **mesma região**. Padronize:
  `export AWS_REGION=us-east-1`.

## Plano B — serviço indisponível na região

Se o Athena estiver instável na região da turma:

1. Troque a região (`us-east-1`, `us-east-2`, `sa-east-1`) e rode o `dry-run.sh`
   de novo (lembre que a **tabela também** precisa existir nessa região).
2. Se persistir, conduza o lab como **demonstração** a partir de um resultado já
   capturado e siga para particionamento. Não gaste tempo de aula subindo
   ambiente — essa é a lição da preparação prévia.
