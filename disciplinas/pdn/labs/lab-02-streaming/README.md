# Lab 02 (PDN) — Streaming: Kinesis + Firehose + Spark

## Por que estamos fazendo isso

Vocês acabaram de ver **Spark Streaming**. Na Aula 2 vimos o equivalente
gerenciado na AWS: **Kinesis Data Streams** (ingestão) + **Firehose** (entrega).
Neste lab você monta um pipeline de streaming de verdade e consome o **mesmo
stream de duas formas**, fechando a ponte "Spark Streaming → streaming na nuvem":

```
produtor (eventos de jogos reais) → Kinesis Data Stream
        ├─ Firehose → S3        (gerenciado, sem código)
        └─ Spark Structured Streaming lê o S3 em micro-batches → agregados
```

## O que você aprende aqui

- Como um **Data Stream** organiza dados em **shards** e como produzir eventos.
- Como o **Firehose** faz *buffering* e entrega no S3 com zero código.
- Como o **Spark Structured Streaming** processa o que aterrissa no S3 em
  **micro-batches** — o mesmo Spark Streaming, agora sobre dados da nuvem.
- Por que o padrão "Firehose aterrissa, Spark processa" é comum em produção.

## Dados do lab

Eventos derivados de **jogos reais e atuais** da Premier League 2024/25
(openfootball, domínio público, sem API key):

```
https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json
```

Um produtor lê esses jogos e os **reproduz como um stream** de eventos (um gol/
partida por vez), simulando tempo real a partir de dados abertos e recentes.

## Pré-requisitos

| Item | Valor |
|---|---|
| Conta AWS | Console + AWS CLI |
| Tipo de usuário | **IAM** (não use root) |
| Região | `us-east-1` (ajuste se necessário) |
| Serviços | Kinesis Data Streams, Kinesis Data Firehose, S3, IAM, EMR Serverless |
| Pré-requisito | role do Firehose (S3) e a Application EMR Serverless do Lab A |
| Ferramentas | AWS CLI v2; Python 3 (produtor) |

## Custo estimado

> **Centavos a ~US$ 0,50.** 1 shard por ~1h (frações de dólar), Firehose por GB
> (mínimo aqui) e um job Spark curto no EMR Serverless. **O shard cobra enquanto
> o stream existir** — faça a **Limpeza**.

## Tempo estimado

Início na **Aula 2** (Kinesis + Firehose → S3). A parte **Spark** fecha no
**sábado** (Aula 3), reusando o EMR Serverless do Lab A. Total ~1h30.

## Resultado esperado

1. Eventos produzidos aparecendo no S3 via **Firehose**.
2. Um job **Spark Structured Streaming** lendo esse S3 e gravando **agregados**
   (ex.: gols por time) de forma incremental.

## Ponto de parada seguro

- **Aula 2:** pare quando os eventos aparecerem no S3 (fim do Firehose).
- **Sábado:** pare quando o Spark gravar o primeiro micro-batch de agregados.

## Limpeza

```bash
aws firehose delete-delivery-stream --delivery-stream-name lab-pdn-firehose
aws kinesis delete-stream --stream-name lab-pdn-stream --enforce-consumer-deletion
aws s3 rm s3://SEU-BUCKET/ --recursive
# a Application EMR Serverless é a do Lab A (apague lá, se não for reusar)
```

## O que isso prova

Que o streaming que vocês viram em Spark tem um **equivalente gerenciado** na
AWS, e que os dois mundos se combinam: o Firehose aterrissa os dados e o **Spark
Structured Streaming** os processa em micro-batches — sem servidor de streaming
para operar.
