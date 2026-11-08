# Lab 02 (PDN) — Troubleshooting

Rode o `dry-run.sh` primeiro — ele valida o ambiente sem criar o stream (o shard
é o que gera custo).

## "Firehose is unable to assume role" ao criar o Firehose

- A role acabou de ser criada e ainda não propagou no IAM (leva alguns
  segundos). Espere ~15 s e rode o `create-delivery-stream` de novo. O
  `passo-a-passo.md` já tem um `sleep 15` antes dele.

## O Spark Streaming (passo 6) falha com "does not support Complete output mode"

- O sink de arquivo (Parquet) só aceita `append`, e agregação sem watermark exige
  `complete`. O `stream_job.py` do passo a passo usa `foreachBatch` para regravar
  o placar a cada micro-batch. Se você copiou uma versão antiga, atualize.
- Se o job termina sem ler nada: o Firehose grava em `eventos/AAAA/MM/DD/HH/`, e
  o file source não desce em subpastas. O script usa o glob `*/*/*/*/`.

## Os eventos não aparecem no S3

- **É buffering, não erro.** O Firehose entrega por tamanho (~1 MB) ou tempo
  (~60s, como configurado). Com poucos eventos, o gatilho é o **tempo** — espere
  ~1 min e liste de novo.
- Confirme que o Firehose tem a fonte apontando para o **ARN do stream** certo e
  que a `FirehoseLabRole` tem acesso ao bucket.

## "AccessDenied" / o Firehose não grava no S3

- Quem grava é a **role do Firehose**, não o seu usuário. A `FirehoseLabRole`
  precisa de escrita no bucket (`AmazonS3FullAccess` no lab) e leitura do Kinesis
  (`AmazonKinesisReadOnlyAccess`). Para criá-la, seu usuário precisa de
  `iam:PassRole`.

## O produtor falha com "ProvisionedThroughputExceeded"

- Você excedeu a capacidade do shard (1 MB/s ou 1000 reg/s). O produtor já usa
  `time.sleep(0.2)`; aumente o intervalo ou adicione shards (lembre do custo).

## "ResourceInUseException" ao criar o stream

- Já existe um stream com esse nome (reexecução). Apague antes:
  `aws kinesis delete-stream --stream-name lab-pdn-stream --enforce-consumer-deletion`.

## O produtor não conecta / `boto3` ausente

- Instale: `python3 -m pip install boto3`. Confirme credencial com
  `aws sts get-caller-identity` (o boto3 usa a mesma credencial da CLI).

## A fonte de dados (openfootball) não respondeu

- Pode ser rede/proxy. Tenha um JSON de backup local e aponte o produtor para o
  arquivo (troque a leitura da URL por `open('jogos.json')`). O dry-run avisa se
  a fonte não estiver acessível na véspera.

## (Spark) O job Structured Streaming não produz agregados

- Confirme que **há arquivos** em `eventos/` (o Firehose já entregou) antes de
  rodar o Spark. Sem arquivos, o stream fica ocioso.
- O **checkpoint** precisa de um caminho limpo por execução. Se reexecutar, use
  um novo prefixo de `checkpointLocation` ou limpe o anterior.
- `outputMode("complete")` recalcula o agregado inteiro a cada micro-batch — ok
  para o lab; em produção, considere `update` + sink adequado.

## (Spark) O job encerra sozinho

- É esperado: `awaitTermination(180)` roda ~3 min e para, para não deixar job de
  streaming consumindo recurso. Para processar mais, aumente o valor.

## Tenho medo de custo esquecido

- **O shard cobra por hora enquanto o stream existir**, mesmo sem tráfego. Apague
  stream e Firehose na limpeza. Confira: `aws kinesis list-streams` e
  `aws firehose list-delivery-streams`.

## Plano B — sem orçamento / serviço indisponível

1. Troque a região e rode o `dry-run.sh` de novo.
2. Sem orçamento, conduza como **demonstração**: produza alguns eventos, mostre o
   S3 populado e rode o Spark sobre um `eventos/` já existente. O conceito
   (ingestão gerenciada + Spark em micro-batches) é aprendido sem manter o stream
   ligado por muito tempo.
