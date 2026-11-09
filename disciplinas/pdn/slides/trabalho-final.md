---
layout: section
class: capa
routeAlias: trabalho-final
---

# Trabalho final

Pipeline e custo do meu clube · **100% da nota** · entrega em **15 dias corridos** após a última aula

<!--
Último slide do deck (e link direto no sumário do site: /pdn/trabalho-final).
Confirme a data exata de entrega e o canal (Classroom) com a turma.
-->

---

## Trabalho final: o que fazer

- Cada grupo recebe **um clube** da Premier League 2024/25 pela matrícula do 1º integrante:
  `python3 tools/trabalho/trabalho.py clube <matricula>`
- **Parte 1 (batch):** job PySpark no **EMR Serverless** com 6 respostas sobre o clube (é o Lab A).
- **Parte 2 (streaming):** os jogos do clube por **Kinesis → Firehose → S3** (é o Lab B).
- **Parte 3 (ADR):** uma decisão de arquitetura **com custo** na [AWS Pricing Calculator](https://calculator.aws/).
- **Bônus opcional (+1,0):** treino no **SageMaker**, sem endpoint ligado.

| | |
|---|---|
| **Vale** | **100% da nota** (aprovação com nota ≥ 6,0) |
| **Quem** | individual ou grupo de até 3, você escolhe |
| **Prazo** | **15 dias corridos** após a última aula |
| **Custo** | US$ 1 a 2 se limpar no mesmo dia |

Enunciado completo e critérios: [`avaliacao/trabalho.md`](https://github.com/obernardocosta/big-data/blob/main/disciplinas/pdn/avaliacao/trabalho.md)

---

## Trabalho final: como entregar

1. Copie o [`trabalho-modelo/`](https://github.com/obernardocosta/big-data/tree/main/disciplinas/pdn/avaliacao/trabalho-modelo)
   e preencha `entrega.json`, `job.py`, `adr.md` e `README.md`.
2. Rode a autoconferência (formato e estrutura, **não** diz se as respostas estão certas):
   `python3 tools/trabalho/trabalho.py validar <pasta> --disciplina pdn`
3. **Limpe os recursos** da sua conta (Application do EMR Serverless, stream do Kinesis,
   Firehose, buckets e, se fez o bônus, o endpoint do SageMaker).
4. Entregue a pasta (zip ou repositório) em até **15 dias corridos** após a última aula.

Dúvidas ou problemas: [abra uma issue](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml).

### Bom trabalho!

<!-- Confirme a data exata (15 dias corridos) e o canal (Classroom). -->
