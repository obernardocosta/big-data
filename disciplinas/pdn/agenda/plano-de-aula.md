# Plano de aula — PDN

Mesmas regras de condução da GDBD (pontualidade, timeboxes, dry-run na véspera,
ponto de parada seguro nos labs). Esta disciplina está em construção: a Aula 1 é
uma **fatia vertical inicial**; as demais serão detalhadas ao migrar o material
original do PDN.

## Regras de condução (valem para todas as aulas)

- **Pontualidade.** Começa no horário, tolerância máxima de 10 min. Avise na Aula 1.
- **Primeiros 30 min a partir da Aula 2** para dúvidas / terminar a atividade
  anterior, enquanto os alunos chegam. Não atrasa conteúdo novo.
- **Respeite o timebox do lab**; use o ponto de parada seguro se estourar.
- **Dry-run na véspera** de cada lab (read-only, sem custo).

## Estrutura padrão de uma aula

Mesma narrativa didática da GDBD:

1. Estudo de caso / problema de negócio
2. Como o mundo open source resolve
3. Trazendo para a AWS (open source → serviço gerenciado)
4. O serviço gerenciado (o que é, como cobra, integrações)
5. Prós e contras / quando usar
6. Prática (lab)
7. Fechamento + dúvidas

## Aula 1 — Processamento em streaming (Kinesis)

Duração de referência: ~2h. Sem o bloco de 30 min (primeira aula).

| Tempo | Bloco |
|---|---|
| 0:00–0:10 | Abertura: apresentação, combinados, **aviso de pontualidade** |
| 0:10–0:35 | Estudo de caso + lote vs streaming |
| 0:35–0:55 | Open source: Apache Kafka (tópicos, partições, TCO) |
| 0:55–1:15 | AWS: família Kinesis (Streams, Firehose, Flink) e MSK |
| 1:15–1:25 | Prós e contras; Kinesis vs MSK |
| 1:25–1:30 | Preparar o lab |
| 1:30–2:15 | **Lab 01 — Kinesis + Firehose → S3** (timebox 45 min) |
| 2:15–2:25 | Fechamento: open source → AWS; convergência com o Data Lake |

Ponto de parada seguro: pare quando o primeiro lote de eventos aparecer no S3.

## Aulas seguintes (a planejar)

Esqueleto sugerido, a refinar com o material original do PDN:

| Aula | Tópico previsto |
|---|---|
| 2 | Processar o stream por evento (AWS Lambda) |
| 3 | Analytics em tempo real (Managed Service for Apache Flink) |
| 4 | Processamento em lote em escala (revisão EMR/Glue sob a ótica de PDN) |
| 5 | Padrões de arquitetura: lambda/kappa, batch + streaming |
| 6 | Projeto final / estudo de caso ponta a ponta |
