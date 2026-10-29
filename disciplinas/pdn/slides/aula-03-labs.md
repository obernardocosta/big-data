---
layout: section
routeAlias: aula-3
---

# Aula 3 — Dia de laboratórios

Mão na massa: EMR Serverless e SageMaker

<!--
Aula 3 da PDN. Aula de sábado (8h-13h, ~5h): foco em LABS.
Consolida a prática das Aulas 1 (EMR Serverless) e 2 (SageMaker).

PONTUALIDADE: primeiros 30 min para dúvidas / terminar atividades das aulas
anteriores, enquanto chegam. Depois, mãos à obra. Ver plano-de-aula.md.
-->

---

## Como vai ser o dia

Aula longa (8h–13h) **dedicada à prática**. Dois labs principais, cada um com
seu `dry-run.sh` (rode na véspera!) e ponto de parada seguro.

| Bloco | Lab | Tempo |
|---|---|---|
| Manhã 1 | **EMR Serverless** (PySpark job + dependências) | ~2h30 |
| Intervalo | — | 15 min |
| Manhã 2 | **Amazon SageMaker** (treino + deploy) | ~1h30 |

> Primeiros 30 min: dúvidas e término de atividades das Aulas 1 e 2.

---

## Lab A — EMR Serverless

**Objetivo:** submeter um job **PySpark** a uma Application EMR Serverless, com
**RuntimeRole por job** e dependências Python.

- Pré-requisitos primeiro (role, bucket, Application).
- **Obrigatório:** EMR Serverless PySpark job.
- **Obrigatório:** Python Dependencies.
- **Extra:** EMR Serverless Hive query.

Instruções versionadas: `labs/lab-01-emr-serverless/`
Base oficial: https://github.com/aws-samples/emr-serverless-samples

---

## Lab B — Amazon SageMaker

**Objetivo:** percorrer o ciclo de ML no SageMaker — **manipular dados, treinar
e fazer o deploy** de um modelo.

- Notebook gerenciado, Training Job, registro e Endpoint.
- Tempo reservado: **1h30**.

Instruções versionadas: `labs/lab-02-sagemaker/`

---

## Lembretes de custo e limpeza

- Os dois labs **geram custo** (EMR Serverless por vCPU/GB-hora; SageMaker por
  segundo de notebook/treino/endpoint).
- **Endpoint do SageMaker é o vilão**: cobra enquanto estiver no ar — **apague**
  ao terminar.
- Rode o `dry-run.sh` de cada lab **antes** e siga a seção **Limpeza** ao final.

---

## Fechamento do curso

A PDN levou o processamento um passo além da GDBD:

- **EMR Serverless** — Spark sem gerenciar cluster; RuntimeRole por job.
- **SageMaker** — ML de ponta a ponta, do Notebook ao Endpoint.
- **Custo é arquitetura** — data store e Firehose mudam a conta em ordens de
  grandeza.

### Obrigado! Dúvidas, seminário e entrega final.

<!-- Fim da PDN. -->
