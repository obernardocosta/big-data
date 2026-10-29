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

## Balanceamento de tempo (refactor)

A carga da PDN pende para o **sábado (Aula 3)**: além do SageMaker (teoria +
Lab C), ele fecharia a parte Spark do Lab B. Para não virar "dia de terminar
tudo", a estratégia é **avançar os labs nas noturnas**, que têm folga:

- **Aula 1 (terça):** teoria de EMR Serverless é curta → **conclua o Lab A hoje**.
- **Aula 2 (quinta):** feche a **ingestão** do Lab B (eventos no S3) hoje.
- **Aula 3 (sábado):** foco no **SageMaker**; sobra só **uma** frente a mais (o
  Spark do Lab B). Os 30 min de chegada são buffer, não conteúdo; reserve
  20–25 min reais para a **limpeza**.

## Aula 1 — EMR Serverless (terça · 18h30–22h · ~3h30)

| Tempo | Bloco |
|---|---|
| 0:00–0:10 | Abertura e combinados (**aviso de pontualidade**) |
| 0:10–0:35 | De onde viemos: Spark/EMR da graduação + GDBD → o peso do cluster |
| 0:35–1:15 | EMR Serverless: Application → Job, **RuntimeRole por job** |
| 1:15–1:35 | Preço e TCO — quando vale |
| 1:35–1:50 | **Intervalo** |
| 1:50–3:20 | **Lab A** — EMR Serverless (completo: job PySpark + dependências) |
| 3:20–3:30 | Fechamento + o que vem (streaming na quinta) |

Ponto de parada seguro do Lab A: job PySpark em `SUCCESS`.

> **Gestão de tempo:** a teoria de EMR Serverless é curta — aproveite a folga da
> noturna para **concluir o Lab A hoje** (incluindo o lab de dependências
> Python), e não só "submeter o job". Isso tira carga do sábado, que já é cheio.

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

> **Gestão de tempo:** feche a **ingestão** (produtor → Kinesis → Firehose → S3)
> hoje. Só a parte **Spark Structured Streaming** fica para o sábado — e é **uma**
> frente, reaproveitando o EMR Serverless do Lab A (já pronto da Aula 1).

## Aula 3 — SageMaker + dia de labs (sábado · 8h–13h · ~5h)

| Tempo | Bloco |
|---|---|
| 0:00–0:30 | Chegada: dúvidas / terminar pendências das Aulas 1–2 |
| 0:30–2:00 | **SageMaker**: notebook → Training Job → deploy (Batch vs Endpoint) |
| 2:00–2:15 | **Intervalo** |
| 2:15–3:30 | **Lab C** — SageMaker (treino + deploy) com calma |
| 3:30–4:15 | **Spark Structured Streaming** do Lab B (fecha o streaming) |
| 4:15–4:40 | **Limpeza** (apagar Endpoint!) e verificação de custo |
| 4:40–5:00 | Revisão do mapa do curso + fechamento |

> **Gestão de tempo:** se as Aulas 1 e 2 fecharam seus labs (como planejado), o
> sábado tem **uma** frente nova de lab (SageMaker) + fechar o Spark do Lab B —
> cabe com folga nas 5h. Os 30 min de chegada são o **buffer** para quem ficou
> para trás; não conte com eles no conteúdo. **Reserve 20–25 min reais para a
> limpeza** — o Endpoint do SageMaker e o shard do Kinesis cobram se esquecidos.

> O SageMaker tem a teoria no **começo do sábado** (turma fresca) e o lab logo
> em seguida. A parte **Spark Structured Streaming** do Lab B (ler o S3 do
> Firehose em micro-batches) é feita neste dia, aproveitando o EMR Serverless
> montado no Lab A.
