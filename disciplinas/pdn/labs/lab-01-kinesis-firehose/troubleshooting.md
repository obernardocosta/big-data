# Lab 01 (PDN) — Troubleshooting

Erros comuns e como resolver. Rode o `dry-run.sh` deste lab primeiro — ele valida
o ambiente sem criar o stream (o shard é o que gera custo).

## Os eventos não aparecem no S3

- **É buffering, não erro.** O Firehose entrega por tamanho (~MB) ou tempo
  (~60–300s). Espere o intervalo e liste de novo. Com poucos eventos, o gatilho
  é o **tempo**.
- Confirme que o Firehose está com a fonte apontando para o **ARN do stream**
  certo e que a role do Firehose tem acesso ao bucket.

## "AccessDenied" / o Firehose não grava no S3

- O **Firehose** grava via a role dele (não o seu usuário). A `FirehoseLabRole`
  precisa de permissão de escrita no bucket (`AmazonS3FullAccess` resolve no lab;
  em produção, restrinja ao bucket).
- Para criar/associar a role, seu usuário precisa de `iam:PassRole`.

## "ResourceInUseException" ao criar o stream

- Já existe um stream com esse nome (reexecução). Use outro nome ou apague o
  anterior: `aws kinesis delete-stream --stream-name <nome>
  --enforce-consumer-deletion`.

## O stream fica em "CREATING" por um tempo

- Normal. Aguarde `ACTIVE`:
  `aws kinesis describe-stream-summary --stream-name <nome>
   --query 'StreamDescriptionSummary.StreamStatus'`.

## "ProvisionedThroughputExceeded" ao enviar eventos

- Você excedeu a capacidade do shard (1 MB/s ou 1000 registros/s por shard).
  Para o lab, envie em ritmo menor ou aumente os shards (lembre do custo).

## Tenho medo de custo esquecido

- **O shard cobra por hora enquanto o stream existir**, mesmo sem tráfego. Faça a
  limpeza: apague o Firehose e o stream. Confirme:
  `aws kinesis list-streams` e `aws firehose list-delivery-streams`.

## Plano B — Kinesis indisponível ou sem orçamento

1. Troque a região e rode o `dry-run.sh` de novo.
2. Sem orçamento, conduza como **demonstração**: mostre a criação no console,
   explique shards e o buffering do Firehose, e use um bucket já populado para
   mostrar os arquivos entregues. O conceito (ingestão de streaming → Data Lake)
   é aprendido mesmo sem criar o stream ao vivo.
