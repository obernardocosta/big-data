# Plano de aula — PDN

Mesmas regras de condução da GDBD (pontualidade, timeboxes, dry-run na véspera,
ponto de parada seguro). Conteúdo migrado dos PDFs das turmas 2024.02/2025.01
(extraídos em `_fonte/pdn_*.txt`).

## Grade horária real

**3 aulas:**

- **2 aulas de 18h–22h** (terça/quinta, ~4h cada) — teoria **mesclada** com
  prática: expõe o conceito e já inicia o lab correspondente.
- **1 aula de 8h–13h** (sábado, ~5h) — **dia de laboratórios**: tempo longo e
  contínuo para os labs práticos (é mais fácil sustentar labs de 1h30–2h30 aqui).

| Aula | Dia / horário | Foco | Tema | Labs |
|---|---|---|---|---|
| 1 | Terça/quinta · 18–22h | Teoria + prática | EMR Serverless + Seminário | prep. Lab 01 |
| 2 | Terça/quinta · 18–22h | Teoria + prática | SageMaker + pipeline ML + custos | prep. Lab 02 |
| 3 | **Sábado · 8–13h** | **Labs** | EMR Serverless e SageMaker na prática | **01 e 02** |

## Regras de condução (todas as aulas)

- **Pontualidade.** Começa no horário, tolerância máxima de 10 min. Avise na Aula 1.
- **Primeiros 30 min a partir da Aula 2** para dúvidas / terminar a atividade
  anterior, enquanto os alunos chegam. Não atrasa conteúdo novo.
- **Respeite o timebox do lab**; use o ponto de parada seguro se estourar.
- **Dry-run na véspera** de cada lab (read-only, sem custo). Nos labs da PDN há
  custo real — reforce a **limpeza** (o **Endpoint do SageMaker** é o maior risco).

## Dinâmica por tipo de aula

- **Terça/quinta (4h, menores):** blocos curtos de teoria + prática intercalados.
  O lab é **iniciado** aqui (pré-requisitos, primeiro job) e **aprofundado** no
  sábado. Bom para manter ritmo numa janela mais curta.
- **Sábado (5h, labs):** janela longa para os labs completos
  (EMR Serverless ~2h30; SageMaker ~1h30), com espaço para troubleshooting ao vivo.

## Aula 1 — EMR Serverless (18h–22h)

| Tempo | Bloco |
|---|---|
| 0:00–0:10 | Abertura: combinados, **aviso de pontualidade** |
| 0:10–0:40 | De onde viemos (EMR tradicional da GDBD) → problema |
| 0:40–1:30 | EMR Serverless: serverless, recurso vs cluster, **RuntimeRole por job** |
| 1:30–2:00 | Application → job; submissão de job Spark |
| 2:00–2:15 | Intervalo |
| 2:15–2:45 | Preço e TCO (vs EMR tradicional) |
| 2:45–3:15 | **Trabalho — Seminário**: formar grupos, sortear serviços |
| 3:15–4:00 | Início do **Lab 01** (pré-requisitos + primeiro PySpark job) |

## Aula 2 — SageMaker + pipeline ML + custos (18h–22h)

| Tempo | Bloco |
|---|---|
| 0:00–0:30 | Dúvidas / andamento do seminário (30 min de chegada) |
| 0:30–1:15 | Problema: ML em produção; etapas (Wrangling/Experiment/Deploy) |
| 1:15–2:00 | SageMaker: o que é, como funciona, "antes × depois" |
| 2:00–2:15 | Intervalo |
| 2:15–3:00 | Pipeline de ML: Batch vs real time; fluxo de produção |
| 3:00–4:00 | Extra — Data store e custos (DynamoDB vs S3 vs Firehose) + início do Lab 02 |

## Aula 3 — Dia de labs (sábado, 8h–13h)

| Tempo | Bloco |
|---|---|
| 0:00–0:30 | Dúvidas / terminar atividades das Aulas 1 e 2 |
| 0:30–3:00 | **Lab 01 — EMR Serverless** (PySpark job + Python dependencies; extra Hive) |
| 3:00–3:15 | Intervalo |
| 3:15–4:45 | **Lab 02 — SageMaker** (treino + deploy) |
| 4:45–5:00 | **Limpeza** (apagar Endpoint!), fechamento, seminário/entrega |
