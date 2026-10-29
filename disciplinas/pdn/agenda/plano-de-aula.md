# Plano de aula — PDN

Mesmas regras de condução da GDBD (pontualidade, timeboxes, dry-run na véspera,
ponto de parada seguro). Conteúdo migrado dos PDFs das turmas 2024.02/2025.01
(extraídos em `_fonte/pdn_*.txt`).

## Grade horária real

**3 aulas**, seguindo a **sequência da semana** (terça → quinta → sábado), numa
única semana:

- **Terça e quinta: 18h30–22h** (~3h30) — teoria **mesclada** com prática.
- **Sábado: 8h–13h** (~5h) — **dia de laboratórios** (janela longa e contínua).

| Aula | Dia / horário | Foco | Tema | Labs |
|---|---|---|---|---|
| 1 | **terça** · 18h30–22h | Teoria + prática | EMR Serverless + Seminário | prep. Lab 01 |
| 2 | **quinta** · 18h30–22h | Teoria + prática | SageMaker + pipeline ML + custos | prep. Lab 02 |
| 3 | **sábado** · 8–13h | **Labs** | EMR Serverless e SageMaker na prática | **01 e 02** |

> As aulas acompanham a semana normal: **terça, quinta e sábado**. O sábado
> (Aula 3) é a janela longa, reservada aos labs. Ajuste as datas ao calendário
> real da turma mantendo essa cadência.

## Regras de condução (todas as aulas)

- **Pontualidade.** Começa no horário, tolerância máxima de 10 min. Avise na Aula 1.
- **Primeiros 30 min a partir da Aula 2** para dúvidas / terminar a atividade
  anterior, enquanto os alunos chegam. Não atrasa conteúdo novo.
- **Respeite o timebox do lab**; use o ponto de parada seguro se estourar.
- **Dry-run na véspera** de cada lab (read-only, sem custo). Nos labs da PDN há
  custo real — reforce a **limpeza** (o **Endpoint do SageMaker** é o maior risco).

## Dinâmica por tipo de aula

- **Terça/quinta ( 3h30, menores):** blocos curtos de teoria + prática intercalados.
  O lab é **iniciado** aqui (pré-requisitos, primeiro job) e **aprofundado** no
  sábado. Bom para manter ritmo numa janela mais curta.
- **Sábado (5h, labs):** janela longa para os labs completos
  (EMR Serverless ~2h30; SageMaker ~1h30), com espaço para troubleshooting ao vivo.

## Aula 1 — EMR Serverless (terça · 18h30–22h)

| Tempo | Bloco |
|---|---|
| 0:00–0:10 | Abertura: combinados, **aviso de pontualidade** |
| 0:10–0:35 | De onde viemos (EMR tradicional da GDBD) → problema |
| 0:35–1:20 | EMR Serverless: serverless, recurso vs cluster, **RuntimeRole por job** |
| 1:20–1:45 | Application → job; submissão de job Spark |
| 1:45–2:00 | Intervalo |
| 2:00–2:25 | Preço e TCO (vs EMR tradicional) |
| 2:25–2:50 | **Trabalho — Seminário**: formar grupos, sortear serviços |
| 2:50–3:30 | Início do **Lab 01** (pré-requisitos + primeiro PySpark job) |

## Aula 2 — SageMaker + pipeline ML + custos (quinta · 18h30–22h)

| Tempo | Bloco |
|---|---|
| 0:00–0:30 | Dúvidas / andamento do seminário (30 min de chegada) |
| 0:30–1:05 | Problema: ML em produção; etapas (Wrangling/Experiment/Deploy) |
| 1:05–1:45 | SageMaker: o que é, como funciona, "antes × depois" |
| 1:45–2:00 | Intervalo |
| 2:00–2:40 | Pipeline de ML: Batch vs real time; fluxo de produção |
| 2:40–3:30 | Extra — Data store e custos (DynamoDB vs S3 vs Firehose) + início do Lab 02 |

## Aula 3 — Dia de labs (sábado, 8h–13h)

| Tempo | Bloco |
|---|---|
| 0:00–0:30 | Dúvidas / terminar atividades das Aulas 1 e 2 |
| 0:30–3:00 | **Lab 01 — EMR Serverless** (PySpark job + Python dependencies; extra Hive) |
| 3:00–3:15 | Intervalo |
| 3:15–4:45 | **Lab 02 — SageMaker** (treino + deploy) |
| 4:45–5:00 | **Limpeza** (apagar Endpoint!), fechamento, seminário/entrega |
