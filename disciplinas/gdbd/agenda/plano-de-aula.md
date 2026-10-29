# Plano de aula — GDBD

Este plano existe para tratar dois pontos do feedback de turmas anteriores:
**atrasos no início** e **labs que estouravam o tempo**. Por isso cada bloco tem
um *timebox* e todo lab tem um ponto de parada seguro.

## Grade horária real

**6 aulas:**

- **4 aulas de 18h–22h** (terça/quinta, ~4h cada) — teoria **mesclada** com
  prática: expõe o conceito e já inicia o lab correspondente na mesma janela.
- **2 aulas de 8h–13h** (sábado, ~5h) — **mais voltadas a laboratórios**: a
  janela longa sustenta os labs mais pesados sem corre-corre.

| Aula | Dia / horário | Foco | Tema | Labs |
|---|---|---|---|---|
| 1 | Terça/quinta · 18–22h | Teoria + prática | Catálogo (Glue Data Catalog) | 01, 02 |
| 2 | Terça/quinta · 18–22h | Teoria + prática | Athena/Presto + particionamento | 03, 04 |
| 3 | Terça/quinta · 18–22h | Teoria + prática | Processamento (Glue Job/Spark) | 05 |
| 4 | Terça/quinta · 18–22h | Teoria + prática | Orquestração (Airflow/Step Functions) | — |
| 5 | **Sábado · 8–13h** | **Labs** | Amazon EMR | 06 (~US$ 1) |
| 6 | **Sábado · 8–13h** | **Labs** | Data Lake (3 camadas) | 07 (final) |

> A ordem de dias pode variar conforme o calendário da turma; o importante é
> que os labs mais pesados (**EMR** e **Data Lake**) caiam nas janelas de
> **sábado**, que têm mais tempo contínuo.

## Dinâmica por tipo de aula

- **Terça/quinta (4h, menores):** blocos curtos de teoria + prática intercalados;
  os labs curtos (01–05) cabem na própria aula. Mantém ritmo na janela menor.
- **Sábado (5h, labs):** janela longa para os labs pesados (EMR e Data Lake),
  com espaço para troubleshooting ao vivo e para o ponto de parada seguro.

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

## Aula 1 — Catálogo de Dados (terça/quinta, 18h–22h)

Primeira aula: sem o bloco de 30 min. Janela de ~4h, teoria + prática.

| Tempo | Bloco |
|---|---|
| 0:00–0:15 | Abertura: apresentação, combinados, **aviso de pontualidade** |
| 0:15–0:50 | Estudo de caso + o problema de "arquivos soltos vs tabelas" |
| 0:50–1:30 | Open source: Hive Metastore → AWS: Glue Data Catalog |
| 1:30–2:00 | O serviço: bancos, tabelas, esquema, cobrança; prós e contras |
| 2:00–2:15 | Intervalo |
| 2:15–2:40 | **Lab 01 — Glue Data Catalog** (timebox 15 min + apoio) |
| 2:40–2:55 | Gancho: "catalogar à mão não escala" → Crawler |
| 2:55–3:40 | **Lab 02 — Glue Crawler** (timebox 30 min + apoio) |
| 3:40–4:00 | Fechamento: open source → AWS; dúvidas; o que vem na Aula 2 |

Pontos de parada seguro: Lab 01 após criar e ver a tabela (passo 4); Lab 02
assim que o Crawler criar a tabela (passo 5). O resto vira demonstração.

## Aulas 2–6 (migradas)

A partir da Aula 2, **reserve os primeiros 30 min** para dúvidas / término da
atividade anterior, enquanto os alunos chegam.

| Aula | Dia · horário | Tópico | Labs |
|---|---|---|---|
| 2 | Terça/quinta · 18–22h | Athena/Presto + particionamento | 03, 04 |
| 3 | Terça/quinta · 18–22h | Processamento — Glue Job / Spark serverless | 05 (custo) |
| 4 | Terça/quinta · 18–22h | Orquestração — Airflow → MWAA / Step Functions | — (conceitual) |
| 5 | **Sábado · 8–13h** | Amazon EMR — Hadoop/Spark gerenciado | 06 (custo ~US$ 1) |
| 6 | **Sábado · 8–13h** | Data Lake — amarrando tudo (3 camadas) | 07 (lab final) |

Nas aulas de **terça/quinta** (4h), intercale teoria e os labs curtos. Nas de
**sábado** (5h), use a janela longa para conduzir os labs pesados por inteiro.

> Nota de preparação: o **Lab 06 (EMR)** foi o que falhou numa turma anterior
> (indisponibilidade de instâncias na região). Ele tem um `dry-run.sh`
> **reforçado** que checa capacidade/quota de EC2; rode-o na véspera e tenha o
> plano B (trocar tipo/região ou demonstrar) pronto.
