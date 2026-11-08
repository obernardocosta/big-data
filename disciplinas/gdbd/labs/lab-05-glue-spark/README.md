# Lab 05 — Spark serverless com AWS Glue Job

## Por que estamos fazendo isso

Nos slides vimos que dado cru raramente chega pronto: colunas demais, formato
pesado, vários arquivos. O **AWS Glue Job** é o **Spark serverless** — roda a
transformação distribuída sem você subir cluster. Neste lab você transforma um
CSV cru em **Parquet + gzip**, o que fecha o ciclo com a Aula 2: a consulta no
Athena fica mais rápida e mais barata (menos "Data scanned").

## O que você aprende aqui

- Como um **Glue Job** executa Spark (PySpark) de forma serverless.
- O papel da **DPU** como unidade de cobrança (DPU-hora).
- Por que converter para **Parquet colunar** reduz custo e tempo de consulta.
- Quando **não** usar Spark (tarefas curtas → Lambda), discutido no slide.

## Como este lab funciona

1. O instrutor faz uma **demo ao vivo** no console.
2. Você repete no **console**, seguindo o [passo a passo](passo-a-passo.md).
3. Cada passo tem o **script AWS CLI** recolhido, para travas ou para ganhar tempo.
   Os passos de preparação (gerar o CSV, escrever o PySpark e a política IAM)
   usam o script como caminho principal.
4. Encontrou algo errado? [Abra uma issue](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+05%5D+&labels=lab).

## Dados do lab

Dados **reais e atuais** da Premier League 2024/25 ([openfootball](https://github.com/openfootball/football.json), cópia no [repo data](https://github.com/obernardocosta/data/tree/main/football)). O passo a passo baixa o JSON e gera o CSV cru que o Glue
Job transforma em Parquet.

## Pré-requisitos

| Item | Valor |
|---|---|
| Conta AWS | com acesso ao Console e à AWS CLI |
| Tipo de usuário | **IAM** (não use o usuário root) |
| Região | `us-east-1` (ajuste se sua turma usar outra) |
| Serviços | AWS Glue (Job/Spark), Amazon S3, Amazon Athena, IAM |
| Pré-requisito | a role de serviço do Glue (a mesma do Lab 02, com acesso ao S3 do lab) |
| Ferramentas | AWS CLI v2 configurada |

## Custo estimado

> **Atenção: este lab TEM custo.** Diferente dos labs anteriores, um Glue Job
> **executa** Spark e é cobrado por **DPU-hora** (mínimo cobrado de 1 minuto).
> Um job curto (2 DPU, poucos minutos) custa **frações de dólar** — estime
> **cerca de US$ 0,10–0,30**. Faça a **Limpeza** e não deixe jobs agendados.

## Tempo estimado

**50 minutos**: ~5 min de demo ao vivo do instrutor + ~45 min de prática no console.
Os scripts AWS CLI (recolhidos em cada passo) servem para acelerar se o tempo apertar.

## Resultado esperado

Um dataset transformado em **Parquet + gzip** no S3 e consultas no Athena sobre
ele respondendo as perguntas de negócio, com **"Data scanned" menor** do que
sobre o CSV original.

## Ponto de parada seguro

Se o tempo acabar, pare assim que o Job terminar com sucesso e o Parquet
aparecer no S3 (passo 5). As consultas de verificação no Athena (passo 6) viram
demonstração.

## Limpeza

Apague na ordem abaixo e **não deixe o job agendado**.

**No console:**

1. [AWS Glue](https://console.aws.amazon.com/glue/) > **ETL jobs** (ou **Jobs**):
   selecione `lab05-transforma-premier` e, em **Actions**, clique em **Delete job(s)**.
   Confira também que não há *trigger* (agendamento) apontando para ele.
2. **Data Catalog > Databases**: selecione `lab05` (criado no Athena no passo 6) e
   clique em **Delete** (as tabelas `premier_csv` e `premier_parquet` somem junto).
3. [Amazon S3](https://console.aws.amazon.com/s3/): abra o seu bucket, **Empty**
   e depois **Delete**.
4. Opcional, só se não for reutilizar: no [IAM](https://console.aws.amazon.com/iam/)
   > **Roles** > `GlueCrawlerLabRole`, remova a política em linha `GlueLabS3Write`
   (ou apague a role inteira).

<details>
<summary>⚡ Prefere o terminal (AWS CLI)? Clique para ver o script</summary>

```bash
aws glue delete-job --job-name lab05-transforma-premier
aws s3 rm s3://SEU-BUCKET/ --recursive
# se criou tabela/catalogo para o Parquet:
# aws glue delete-table --database-name <DB> --name <TABELA>
# remova a role do lab se não for reutilizá-la
```

</details>

## O que isso prova

Que processamento distribuído na AWS pode ser **serverless e barato**: o mesmo
serviço (Glue) que cataloga os dados também os transforma. E que o **formato**
importa tanto quanto a partição — Parquet colunar ataca de novo o custo por TB
escaneado do Athena.
