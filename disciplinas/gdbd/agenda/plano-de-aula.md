# Plano de aula — GDBD

Este plano existe para tratar dois pontos do feedback de turmas anteriores:
**atrasos no início** e **labs que estouravam o tempo**. Por isso cada bloco tem
um *timebox* e todo lab tem um ponto de parada seguro.

## Regras de condução (valem para todas as aulas)

- **Pontualidade.** A aula começa no horário, com tolerância máxima de 10 min.
  Avise isso explicitamente na **Aula 1**.
- **Primeiros 30 min a partir da Aula 2.** No início da Aula 2 em diante, os
  primeiros 30 minutos são para dúvidas e para terminar a atividade da aula
  anterior, enquanto os alunos vão chegando. Isso **não** atrasa conteúdo novo —
  o conteúdo começa depois desse bloco.
- **Respeite o timebox do lab.** Se o tempo estourar, use o *ponto de parada
  seguro* do lab (está no `README.md` de cada lab) e siga em frente. Prefira um
  lab bem conduzido a vários corridos.
- **Dry-run na véspera.** Rode o `dry-run.sh` de cada lab no dia anterior. Ele é
  read-only e não gera custo; é o que evita o ambiente falhar na frente da turma.

## Estrutura padrão de uma aula

Cada tópico segue a narrativa didática do curso:

1. Estudo de caso / problema de negócio
2. Como o mundo open source resolve (Hive, Presto, Airflow, Hadoop…)
3. Trazendo para a AWS (open source → serviço gerenciado)
4. O serviço gerenciado (o que é, como cobra, integrações)
5. Prós e contras / quando usar
6. Prática (lab)
7. Fechamento: "open source → serviço AWS" e dúvidas

## Aula 1 — Catálogo de Dados (Glue Data Catalog)

Duração de referência: ~2h. Sem o bloco de 30 min (é a primeira aula).

| Tempo | Bloco |
|---|---|
| 0:00–0:10 | Abertura: apresentação, combinados, **aviso de pontualidade** |
| 0:10–0:35 | Estudo de caso + o problema de "arquivos soltos vs tabelas" |
| 0:35–0:55 | Open source: Hive Metastore → AWS: Glue Data Catalog |
| 0:55–1:10 | O serviço: bancos, tabelas, esquema, cobrança; prós e contras |
| 1:10–1:25 | **Lab 01 — Glue Data Catalog** (timebox 15 min) |
| 1:25–1:35 | Intervalo |
| 1:35–1:40 | Gancho: "catalogar à mão não escala" → Crawler |
| 1:40–2:10 | **Lab 02 — Glue Crawler** (timebox 30 min) |
| 2:10–2:20 | Fechamento: open source → AWS; dúvidas; o que vem na Aula 2 |

Pontos de parada seguro: Lab 01 após criar e ver a tabela (passo 4); Lab 02
assim que o Crawler criar a tabela (passo 5). O resto vira demonstração.

## Aulas 2–6 (migradas)

A partir da Aula 2, **reserve os primeiros 30 min** para dúvidas / término da
atividade anterior, enquanto os alunos chegam.

| Aula | Tópico | Labs |
|---|---|---|
| 2 | Athena / Presto — consultar o catálogo com SQL + particionamento | 03, 04 |
| 3 | Processamento — AWS Glue Job / Spark serverless | 05 (custo) |
| 4 | Orquestração — Airflow → MWAA / Step Functions | — (conceitual) |
| 5 | Amazon EMR — Hadoop/Spark gerenciado | 06 (custo ~US$ 1) |
| 6 | Data Lake — amarrando tudo (3 camadas) | 07 (lab final) |

> Nota de preparação: o **Lab 06 (EMR)** foi o que falhou numa turma anterior
> (indisponibilidade de instâncias na região). Ele tem um `dry-run.sh`
> **reforçado** que checa capacidade/quota de EC2; rode-o na véspera e tenha o
> plano B (trocar tipo/região ou demonstrar) pronto.
