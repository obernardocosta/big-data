# Plano de aula — PDN

Mesmas regras de condução da GDBD (pontualidade, timeboxes, dry-run na véspera,
ponto de parada seguro). Conteúdo migrado dos PDFs das turmas 2024.02/2025.01
(extraídos em `_fonte/pdn_*.txt`) e organizado com um fio condutor.

## Fio condutor

Os alunos chegam à PDN tendo acabado de ver **Spark** e **Spark Streaming**. A
GDBD terminou em **Data Lake** (dado parado, catalogado). A PDN responde:

> "Você já sabe **processar com Spark** (batch e streaming). Agora: como fazer
> isso **na nuvem, gerenciado** — e o que mais a nuvem te dá: **dados em tempo
> real** e **machine learning**."

Arco das aulas:

1. **Spark batch → EMR Serverless** (processar sem operar cluster).
2. **Spark Streaming → Kinesis + Firehose** (streaming gerenciado) — protagonista.
3. **SageMaker** (inteligência sobre o dado) + dia de labs.

O bloco **"custo é arquitetura"** (DynamoDB vs S3 vs Firehose) entra junto do
streaming, porque o Firehose é peça dos dois assuntos.

## Grade horária real

**3 aulas**, seguindo a semana (terça → quinta → sábado), ~12h no total:

- **Terça e quinta: 18h30–22h** (~3h30) — teoria + início de lab.
- **Sábado: 8h–13h** (~5h) — teoria do SageMaker + **dia de labs**.

| Aula | Dia / horário | Tema | Lab (início) |
|---|---|---|---|
| 1 | terça · 18h30–22h | Processamento serverless (EMR Serverless) | Lab A |
| 2 | quinta · 18h30–22h | **Streaming na AWS** (Kinesis + Firehose) + custo | Lab B |
| 3 | sábado · 8h–13h | SageMaker (ML) + **dia de labs** | Lab C + fechar A/B |

## Labs (construídos do zero, tema futebol)

- **Lab A — EMR Serverless (PySpark batch):** Application + RuntimeRole + job.
- **Lab B — Streaming (Kinesis + Firehose + Spark):** produtor gera eventos →
  Kinesis Data Stream → **dois consumos**: (1) Firehose → S3 (gerenciado, zero
  código) e (2) **Spark Structured Streaming** lendo o S3 que o Firehose gerou
  (micro-batches) → agregados. Mostra os dois padrões sobre o mesmo stream.
- **Lab C — SageMaker:** treino (Training Job) + deploy (Batch vs Endpoint).

Cada lab tem README, passo-a-passo, `dry-run.sh` (read-only, sem custo) e
troubleshooting. Todos têm custo real → destaque e **Limpeza** (o **Endpoint** do
SageMaker é o maior risco).

## Regras de condução (todas as aulas)

- **Pontualidade.** Começa no horário (18h30/8h), tolerância 10 min. Avise na Aula 1.
- **Primeiros 30 min a partir da Aula 2**: dúvidas / terminar atividade anterior.
- **Respeite o timebox do lab**; use o ponto de parada seguro se estourar.
- **Dry-run na véspera** de cada lab. Reforce a **limpeza** (custo real na PDN).

## Aula 1 — EMR Serverless (terça · 18h30–22h · ~3h30)

| Tempo | Bloco |
|---|---|
| 0:00–0:10 | Abertura e combinados (**aviso de pontualidade**) |
| 0:10–0:35 | De onde viemos: Spark/EMR da graduação + GDBD → o peso do cluster |
| 0:35–1:20 | EMR Serverless: Application → Job, **RuntimeRole por job** |
| 1:20–1:45 | Preço e TCO — quando vale |
| 1:45–2:00 | **Intervalo** |
| 2:00–3:20 | **Lab A** — EMR Serverless (pré-requisitos + primeiro job PySpark) |
| 3:20–3:30 | Fechamento + o que vem (streaming na quinta) |

Ponto de parada seguro do Lab A: job submetido e em execução.

## Aula 2 — Streaming na AWS (quinta · 18h30–22h · ~3h30)

| Tempo | Bloco |
|---|---|
| 0:00–0:30 | Chegada: dúvidas da Aula 1 / terminar Lab A |
| 0:30–1:00 | Ponte: Spark Streaming → streaming gerenciado (e onde o Flink entra) |
| 1:00–1:40 | **Kinesis Data Streams** (shards) e **Firehose** (buffering → S3) |
| 1:40–2:00 | **Custo é arquitetura**: DynamoDB vs S3 vs Firehose |
| 2:00–2:15 | **Intervalo** |
| 2:15–3:20 | **Lab B** — produtor → Kinesis → Firehose → S3 (início) |
| 3:20–3:30 | Fechamento + o que vem (SageMaker no sábado) |

Ponto de parada seguro do Lab B: eventos chegando no S3 via Firehose.

## Aula 3 — SageMaker + dia de labs (sábado · 8h–13h · ~5h)

| Tempo | Bloco |
|---|---|
| 0:00–0:30 | Chegada: dúvidas / terminar Labs A e B |
| 0:30–2:00 | **SageMaker**: notebook → Training Job → deploy (Batch vs Endpoint) |
| 2:00–2:15 | **Intervalo** |
| 2:15–3:15 | **Lab C** — SageMaker (treino + deploy) |
| 3:15–4:30 | **Labs** — fechar Lab A (EMR Serverless) e a parte Spark do Lab B |
| 4:30–4:50 | **Limpeza** (apagar Endpoint!) e verificação de custo |
| 4:50–5:00 | Fechamento do curso |

> O SageMaker tem a teoria no **começo do sábado** (turma fresca) e o lab logo
> em seguida. A parte **Spark Structured Streaming** do Lab B (ler o S3 do
> Firehose em micro-batches) é feita neste dia, aproveitando o EMR Serverless
> montado no Lab A.
