# ADR — (título da decisão)

Um ADR (*Architecture Decision Record*) registra uma decisão de arquitetura, as
alternativas e o porquê. Máximo de uma página.

## Contexto

(O cenário: volume de dados, frequência, quem consome. Declare as premissas
numéricas que você usou, ex.: "2 GB por dia, job 1x por dia".)

## Alternativas

- **A —** (ex.: EMR Serverless)
- **B —** (ex.: cluster EMR transient, ou Firehose vs DynamoDB)

## Custo

(Estimativa mensal de cada alternativa com a
[AWS Pricing Calculator](https://calculator.aws/), com o link ou print da
estimativa. Os valores devem bater com `custo` no `entrega.json`.)

## Decisão

(Qual você escolheu e por quê. Custo não é o único critério: fale de operação,
elasticidade, latência. Diga em que cenário a decisão mudaria.)
