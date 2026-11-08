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

## Como este lab funciona

1. O instrutor faz uma **demo ao vivo** no console.
2. Você repete no **console**, seguindo o [passo a passo](passo-a-passo.md).
3. Cada passo tem o **script AWS CLI** recolhido, para travas ou para ganhar tempo.
4. Encontrou algo errado? [Abra uma issue](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+04%5D+&labels=lab).

## Dados do lab

Dados **reais e atuais** da Premier League 2024/25 ([openfootball](https://github.com/openfootball/football.json), cópia no [repo data](https://github.com/obernardocosta/data/tree/main/football)),
**particionados por `year`/`month`** a partir da data real de cada jogo. O passo
a passo gera a árvore de partições a partir do JSON.

> Quer outro dataset (como no exercício original)? O repo
> [data](https://github.com/obernardocosta/data/tree/main/football) tem outras
> temporadas e ligas (La Liga, Bundesliga, Serie A, Ligue 1), todas no mesmo formato.

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

**50 minutos**: ~5 min de demo ao vivo do instrutor + ~45 min de prática no console.
Os scripts AWS CLI (recolhidos em cada passo) servem para acelerar se o tempo apertar.

## Resultado esperado

Uma tabela **particionada** no catálogo e a comprovação de que consultas que
filtram pela partição no `WHERE` apresentam **"Data scanned" menor** do que as
que não filtram.

## Ponto de parada seguro

Se o tempo acabar, pare assim que o Crawler criar a tabela com as colunas de
partição (passo 4) e você rodar **uma** consulta filtrando a partição (passo 5).
A comparação de scan com/sem filtro pode virar demonstração.

## Limpeza

Para não deixar nada para trás, apague na ordem abaixo.

**No console:**

1. [AWS Glue](https://console.aws.amazon.com/glue/) > **Crawlers**: selecione
   `crawler-particionado` e clique em **Delete**.
2. **Data Catalog > Tables**: selecione a tabela criada (`tabela`) e clique em
   **Delete**.
3. **Data Catalog > Databases**: selecione `futebol_part` e clique em **Delete**.
4. [Amazon S3](https://console.aws.amazon.com/s3/): esvazie (**Empty**) e apague
   (**Delete**) o bucket de dados (`gdbd-lab04-...`) e o bucket de results
   (`gdbd-lab04-results-...`).
5. [IAM](https://console.aws.amazon.com/iam/) > **Roles**: apague a
   `GlueCrawlerLabRole` se não for reutilizá-la.

<details>
<summary>⚡ Prefere o terminal (AWS CLI)? Clique para ver o script</summary>

```bash
aws glue delete-crawler  --name crawler-particionado
aws glue delete-table    --database-name futebol_part --name <TABELA>
aws glue delete-database  --name futebol_part
aws s3 rm s3://SEU-BUCKET/ --recursive
# remova a role do lab se não for reutilizá-la
```

</details>

## O que isso prova

Que o **layout físico dos dados** afeta diretamente custo e desempenho da
consulta: o mesmo motor (Athena) e o mesmo catálogo (Glue), mas lendo menos
dados porque o filtro bate na partição. É a primeira grande otimização de um
Data Lake — e abre caminho para formatos colunares como Parquet.
