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

**45 minutos.**

## Resultado esperado

Um dataset transformado em **Parquet + gzip** no S3 e consultas no Athena sobre
ele respondendo as perguntas de negócio, com **"Data scanned" menor** do que
sobre o CSV original.

## Ponto de parada seguro

Se o tempo acabar, pare assim que o Job terminar com sucesso e o Parquet
aparecer no S3 (passo 5). As consultas de verificação no Athena (passo 6) viram
demonstração.

## Limpeza

```bash
aws glue delete-job --job-name lab05-transforma-premier
aws s3 rm s3://SEU-BUCKET/ --recursive
# se criou tabela/catalogo para o Parquet:
# aws glue delete-table --database-name <DB> --name <TABELA>
# remova a role do lab se não for reutilizá-la
```

## O que isso prova

Que processamento distribuído na AWS pode ser **serverless e barato**: o mesmo
serviço (Glue) que cataloga os dados também os transforma. E que o **formato**
importa tanto quanto a partição — Parquet colunar ataca de novo o custo por TB
escaneado do Athena.
