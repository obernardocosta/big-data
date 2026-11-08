# Trabalho final — PDN: Pipeline e custo do meu clube

Vale **100% da nota** (veja o [`README` da avaliação](README.md)); os labs não valem
nota, são o treino para este trabalho (o Lab A é a Parte 1 e o Lab B, a Parte 2). Pode ser feito
**individualmente ou em grupo de até 3 pessoas**; a nota do trabalho é a mesma
para todos do grupo.

- **Tempo estimado:** 5 a 7 horas.
- **Prazo:** 10 dias corridos após a última aula (o instrutor confirma a data na Aula 1).
- **Onde roda:** na **sua própria conta AWS**, região `us-east-1`.
- **Custo aproximado:** US$ 1 a US$ 2 se você **limpar tudo no mesmo dia**
  (EMR Serverless e Kinesis cobram por uso/hora). O bônus do SageMaker soma cerca
  de US$ 1. Estimativa a partir dos testes dos labs; confira em
  [EMR](https://aws.amazon.com/emr/pricing/),
  [Kinesis Data Streams](https://aws.amazon.com/kinesis/data-streams/pricing/) e
  [Firehose](https://aws.amazon.com/firehose/pricing/).

## Por que este trabalho

A PDN defende uma ideia: **custo é arquitetura**. Nos labs você rodou cada peça
(EMR Serverless, Kinesis + Firehose). Aqui você monta batch e streaming para um
recorte seu **e defende uma decisão de arquitetura com números**, como se
apresentasse a um time que vai pagar a conta.

## O que você aprende

- Rodar um job PySpark **sem operar cluster** (EMR Serverless, RuntimeRole por job).
- Ingerir eventos com **Kinesis + Firehose** e conferir que nada se perdeu.
- Estimar custo com a [AWS Pricing Calculator](https://calculator.aws/) e
  **registrar uma decisão** (ADR) com alternativas e trade-offs.

## O seu clube

Cada grupo trabalha com **um clube** da Premier League 2024/25, definido pela
matrícula do **primeiro integrante** listado:

```bash
python3 tools/trabalho/trabalho.py clube 2024001
```

O script está em [`tools/trabalho`](https://github.com/obernardocosta/big-data/tree/main/tools/trabalho).
Os dados são os mesmos dos labs, do nosso
[repositório de dados](https://github.com/obernardocosta/data/tree/main/football)
(fonte original: [openfootball](https://github.com/openfootball/football.json)).

## O que fazer

### Parte 1 — Batch no EMR Serverless

Escreva um `job.py` (PySpark) que lê os jogos do S3, filtra o seu clube e calcula
as 6 respostas abaixo, gravando o resultado no S3. Rode no
[EMR Serverless](https://console.aws.amazon.com/emr/) como no
[Lab A](https://github.com/obernardocosta/big-data/tree/main/disciplinas/pdn/labs/lab-01-emr-serverless),
com uma RuntimeRole só com o acesso necessário. Registre `emr_application_id` e
`emr_job_run_id`.

| Chave | Definição |
|---|---|
| `jogos` | Quantos jogos o clube disputou. |
| `vitorias` | Número de vitórias. |
| `gols_pro` | Gols marcados. |
| `gols_contra` | Gols sofridos. |
| `media_gols_por_jogo` | (gols marcados + sofridos) ÷ jogos, com 2 casas decimais. |
| `adversario_mais_gols_marcados` | Adversário contra quem o clube mais marcou no total (casa + fora). Empate: ordem alfabética. |

### Parte 2 — Streaming com Kinesis + Firehose

Envie cada jogo do seu clube como **um evento** (exatamente uma vez) por um
produtor, passando por
[Kinesis Data Streams](https://console.aws.amazon.com/kinesis/) e
[Firehose](https://console.aws.amazon.com/firehose/) até o S3, como no
[Lab B](https://github.com/obernardocosta/big-data/tree/main/disciplinas/pdn/labs/lab-02-streaming).
Conte os registros que chegaram no S3 e informe em `eventos_no_s3` (deve ser igual
a `jogos`). Informe em `firehose_buffer_segundos` o intervalo de *buffering* que
você configurou (use 60 ou mais) e, no README, **explique por que o dado não
aparece no S3 na hora**.

### Parte 3 — ADR: a decisão de arquitetura

Escolha **um** dos cenários e escreva o `adr.md` (máximo de uma página, modelo no
`trabalho-modelo/`):

- **Cenário A:** o job da Parte 1 passa a processar **50 GB por dia**. EMR
  Serverless ou cluster EMR transient?
- **Cenário B:** os eventos da Parte 2 passam a **1 milhão por dia**. Guardar no
  S3 via Firehose ou no [DynamoDB](https://aws.amazon.com/dynamodb/pricing/)?

Compare as duas alternativas (`a` e `b`) com a
[AWS Pricing Calculator](https://calculator.aws/), **declarando as premissas**,
e informe os custos mensais em `custo` no `entrega.json`. Escolha com argumentos
além do preço (operação, elasticidade, latência) e diga **em que situação a
decisão mudaria**.

### Bônus opcional — SageMaker (+1,0)

Rode o treino do [Lab C](https://github.com/obernardocosta/big-data/tree/main/disciplinas/pdn/labs/lab-03-sagemaker)
na sua conta, usando **Batch Transform, não endpoint**. Informe o nome do treino
em `bonus.sagemaker.training_job` e marque `endpoint_removido: true` confirmando
que nenhum endpoint ficou ligado. Contas novas costumam ter **quota 0** para
treino no SageMaker: peça o aumento no console com antecedência (pode levar horas).
A nota do trabalho é limitada a 10,0.

## O que entregar

Uma pasta (zip ou repositório) com os arquivos do
[`trabalho-modelo/`](https://github.com/obernardocosta/big-data/tree/main/disciplinas/pdn/avaliacao/trabalho-modelo)
preenchidos:

```
entrega.json    # identificação, respostas, IDs do EMR, eventos, custos, bônus
job.py          # o job PySpark da Parte 1
adr.md          # seções: Contexto, Alternativas, Custo, Decisão
README.md       # o que foi feito, conexão com o conteúdo, limpeza
```

**Antes de entregar**, rode a autoconferência (ela checa formato e estrutura, mas
**não** diz se as respostas estão certas):

```bash
python3 tools/trabalho/trabalho.py validar minha-entrega --disciplina pdn
```

## Como será corrigido (10,0 pontos = 100% da nota)

| Parte | Pontos | Como |
|---|---|---|
| Respostas corretas | 3,0 | automático (6 × 0,5) |
| Streaming: `eventos_no_s3` = `jogos`; buffer informado | 1,0 | automático |
| Estrutura do `adr.md` e `job.py` com SparkSession | 1,0 | automático |
| Evidências do EMR; custos informados para as duas alternativas | 1,0 | automático |
| Qualidade do ADR: alternativas, trade-offs, quando a decisão mudaria | 1,5 | instrutor |
| Premissas e custos coerentes com a Calculator | 1,0 | instrutor |
| README conecta o trabalho ao conteúdo (por que gerenciado, RuntimeRole, buffering) | 1,0 | instrutor |
| Limpeza feita e entrega organizada | 0,5 | instrutor |
| Bônus SageMaker | +1,0 | automático (teto de 10,0) |

## Limpeza (obrigatória)

Apague: Application do EMR Serverless, stream do Kinesis, entrega do Firehose,
buckets (esvazie antes), roles criadas e, se fez o bônus, o **endpoint** do
SageMaker (o maior risco de cobrança). Liste o que apagou no README.

## Encontrou um problema neste trabalho?

[Abra uma issue](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml).
