# Lab 01 (PDN) — Ingestão com Kinesis + Firehose → S3

## Por que estamos fazendo isso

Nos slides vimos que muitos dados chegam **sem parar** (clickstream, logs, IoT) e
que o **Amazon Kinesis** é o streaming gerenciado da AWS. Neste lab você ingere
eventos num **Kinesis Data Stream** e usa o **Firehose** para entregá-los no
**S3** — conectando o mundo de streaming ao Data Lake que você já conhece da
GDBD.

## O que você aprende aqui

- Como um **Data Stream** organiza dados em **shards**.
- Como o **Firehose** faz *buffering* e entrega no S3 com pouco código.
- Por que streaming e lote **convergem** no mesmo Data Lake.
- A base para processamento em tempo real (Lambda/Flink nas próximas aulas).

## Pré-requisitos

| Item | Valor |
|---|---|
| Conta AWS | com acesso ao Console e à AWS CLI |
| Tipo de usuário | **IAM** (não use o usuário root) |
| Região | `us-east-1` (ajuste se sua turma usar outra) |
| Serviços | Amazon Kinesis Data Streams, Kinesis Data Firehose, Amazon S3, IAM |
| Pré-requisito | uma role para o Firehose gravar no S3 (o passo a passo mostra) |
| Ferramentas | AWS CLI v2 configurada |

## Custo estimado

> **Centavos.** Kinesis cobra por shard-hora e por volume; um stream de **1
> shard** por ~30–45 min e poucos eventos custa **frações de dólar**. O Firehose
> cobra por GB ingerido (pouquíssimo aqui). **Faça a Limpeza** — o shard cobra
> enquanto o stream existir.

## Tempo estimado

**45 minutos.**

## Resultado esperado

Eventos enviados ao Data Stream aparecendo como **arquivos no S3**, entregues
pelo Firehose.

## Ponto de parada seguro

Se o tempo acabar, pare assim que o primeiro lote de eventos aparecer no S3
(passo 5). A parte de inspeção/consulta vira demonstração.

## Limpeza

```bash
aws firehose delete-delivery-stream --delivery-stream-name lab-pdn-firehose
aws kinesis delete-stream --stream-name lab-pdn-stream --enforce-consumer-deletion
aws s3 rm s3://SEU-BUCKET/ --recursive
# remova a role do Firehose se não for reutilizá-la
```

## O que isso prova

Que dados em **tempo real** entram no mesmo Data Lake dos dados em lote, com
serviço gerenciado e pouco código. É o ponto de partida para processar o stream
(reagir por evento com Lambda, agregar com Flink).
