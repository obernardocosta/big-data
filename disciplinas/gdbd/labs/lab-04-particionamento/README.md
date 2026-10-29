# Lab 04 — Particionamento no S3

## Por que estamos fazendo isso

No Lab 03 vimos que o Athena cobra por **dados escaneados** (US$ 5/TB). Se toda
consulta lê a tabela inteira, você paga a tabela inteira toda vez. Nos slides
vimos que o **particionamento** resolve isso: organizando os arquivos em
subpastas por coluna (ano/mês/dia), uma consulta que filtra por partição lê
**só o pedaço que importa**. Neste lab você prova isso medindo o scan com e sem
filtro de partição.

## O que você aprende aqui

- Como estruturar dados particionados no S3 (`year=.../month=.../day=...`).
- Como o Crawler detecta pastas de partição como **colunas** da tabela.
- Como filtrar por partição no `WHERE` para **reduzir o scan** (custo e tempo).
- A ligação direta entre layout dos dados e a conta no fim do mês.

## Dados do lab

Dados **reais e atuais** da Premier League 2024/25 (openfootball, sem API key),
**particionados por `year`/`month`** a partir da data real de cada jogo. O passo
a passo gera a árvore de partições a partir do JSON.

## Pré-requisitos

| Item | Valor |
|---|---|
| Conta AWS | com acesso ao Console e à AWS CLI |
| Tipo de usuário | **IAM** (não use o usuário root) |
| Região | `us-east-1` (ajuste se sua turma usar outra) |
| Serviços | Amazon S3, AWS Glue (Crawler + Catalog), Amazon Athena, IAM |
| Pré-requisito | a role de serviço do Glue do Lab 02 (ou criar de novo) |
| Ferramentas | AWS CLI v2 configurada |

## Custo estimado

**Centavos.** Poucos KB no S3, varredura curta do Crawler e consultas pequenas
no Athena. Faça a **Limpeza** ao final mesmo assim.

## Tempo estimado

**45 minutos.**

## Resultado esperado

Uma tabela **particionada** no catálogo e a comprovação de que consultas que
filtram pela partição no `WHERE` apresentam **"Data scanned" menor** do que as
que não filtram.

## Ponto de parada seguro

Se o tempo acabar, pare assim que o Crawler criar a tabela com as colunas de
partição (passo 4) e você rodar **uma** consulta filtrando a partição (passo 5).
A comparação de scan com/sem filtro pode virar demonstração.

## Limpeza

```bash
aws glue delete-crawler  --name crawler-particionado
aws glue delete-table    --database-name futebol_part --name <TABELA>
aws glue delete-database  --name futebol_part
aws s3 rm s3://SEU-BUCKET/ --recursive
# remova a role do lab se não for reutilizá-la
```

## O que isso prova

Que o **layout físico dos dados** afeta diretamente custo e desempenho da
consulta: o mesmo motor (Athena) e o mesmo catálogo (Glue), mas lendo menos
dados porque o filtro bate na partição. É a primeira grande otimização de um
Data Lake — e abre caminho para formatos colunares como Parquet.
