# Plano de aula — GDBD

Este plano existe para tratar dois pontos do feedback de turmas anteriores:
**atrasos no início** e **labs que estouravam o tempo**. Por isso cada bloco tem
um *timebox* e todo lab tem um ponto de parada seguro.

## Grade horária real

**6 aulas**, seguindo a **sequência da semana** (terça → quinta → sábado), ao
longo de **2 semanas**:

- **Terça e quinta: 18h30–22h** (~3h30) — teoria **mesclada** com prática.
- **Sábado: 8h–13h** (~5h) — janela longa, **mais voltada a laboratórios**.

| Aula | Dia / horário | Foco | Tema | Labs |
|---|---|---|---|---|
| 1 | Semana 1 · **terça** 18h30–22h | Teoria + prática | Catálogo (Glue Data Catalog) | 01, 02 |
| 2 | Semana 1 · **quinta** 18h30–22h | Teoria + prática | Athena/Presto + particionamento | 03, 04 |
| 3 | Semana 1 · **sábado** 8–13h | **Labs** | Processamento (Glue Job/Spark) | 05 |
| 4 | Semana 2 · **terça** 18h30–22h | Teoria + prática | Orquestração (Airflow/Step Functions) | — |
| 5 | Semana 2 · **quinta** 18h30–22h | Teoria + prática | Amazon EMR | 06 (~US$ 1) |
| 6 | Semana 2 · **sábado** 8–13h | **Labs** | Data Lake (3 camadas) | 07 (final) |

> As aulas acompanham o calendário normal da semana: **terça, quinta e sábado**,
> repetindo na semana seguinte. Os sábados (Aulas 3 e 6) são as janelas longas,
> boas para lab. Ajuste as datas ao calendário real da turma mantendo essa
> cadência.

## Dinâmica por tipo de aula

- **Terça/quinta (3h30):** blocos curtos de teoria + prática intercalados; os labs
  dessas aulas (01–02, 03–04, 06) cabem na janela, com ponto de parada seguro.
- **Sábado (5h):** janela longa para conduzir com calma — Aula 3 (Glue/Spark) e
  Aula 6 (Data Lake), com espaço para troubleshooting ao vivo.

> **Atenção — Lab 06 (EMR) cai numa quinta (3h30), não no sábado.** Como é o lab
> mais pesado e historicamente problemático (~US$ 1, instâncias que podem não
> subir), rode o `dry-run.sh` **reforçado** na véspera e seja rígido com o ponto
> de parada seguro; se o cluster não subir rápido, vá direto para o plano B
> (demonstração), já que a janela de 3h30 é mais curta.

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

## Aula 1 — Catálogo de Dados (Semana 1 · terça, 18h30–22h)

Primeira aula: sem o bloco de 30 min. Janela de ~3h30, teoria + prática.

| Tempo | Bloco |
|---|---|
| 0:00–0:15 | Abertura: apresentação, combinados, **aviso de pontualidade** |
| 0:15–0:45 | Estudo de caso + o problema de "arquivos soltos vs tabelas" |
| 0:45–1:20 | Open source: Hive Metastore → AWS: Glue Data Catalog |
| 1:20–1:45 | O serviço: bancos, tabelas, esquema, cobrança; prós e contras |
| 1:45–2:00 | Intervalo |
| 2:00–2:25 | **Lab 01 — Glue Data Catalog** (timebox 15 min + apoio) |
| 2:25–2:40 | Gancho: "catalogar à mão não escala" → Crawler |
| 2:40–3:15 | **Lab 02 — Glue Crawler** (timebox 30 min + apoio) |
| 3:15–3:30 | Fechamento: open source → AWS; dúvidas; o que vem na Aula 2 |

Pontos de parada seguro: Lab 01 após criar e ver a tabela (passo 4); Lab 02
assim que o Crawler criar a tabela (passo 5). O resto vira demonstração.

## Aulas 2–6 (migradas)

A partir da Aula 2, **reserve os primeiros 30 min** para dúvidas / término da
atividade anterior, enquanto os alunos chegam.

| Aula | Dia · horário | Tópico | Labs |
|---|---|---|---|
| 2 | Sem. 1 · quinta 18h30–22h | Athena/Presto + particionamento | 03, 04 |
| 3 | Sem. 1 · **sábado 8–13h** | Processamento — Glue Job / Spark serverless | 05 (custo) |
| 4 | Sem. 2 · terça 18h30–22h | Orquestração — Airflow → MWAA / Step Functions | — (conceitual) |
| 5 | Sem. 2 · quinta 18h30–22h | Amazon EMR — Hadoop/Spark gerenciado | 06 (custo ~US$ 1) |
| 6 | Sem. 2 · **sábado 8–13h** | Data Lake — amarrando tudo (3 camadas) | 07 (lab final) |

Nas aulas de **terça/quinta** (3h30), intercale teoria e os labs. Nas de
**sábado** (5h, Aulas 3 e 6), use a janela longa para conduzir o lab por inteiro.

> Nota de preparação: o **Lab 06 (EMR)** foi o que falhou numa turma anterior
> (indisponibilidade de instâncias na região) e cai numa **quinta (3h30)**. Ele tem
> um `dry-run.sh` **reforçado** que checa capacidade/quota de EC2; rode-o na
> véspera e tenha o plano B (trocar tipo/região ou demonstrar) pronto — a janela
> noturna é mais curta, então não insista se o cluster não subir.
