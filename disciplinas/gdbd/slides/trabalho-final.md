---
layout: section
routeAlias: trabalho-final
---

# Trabalho final

Data Lake do meu clube · **100% da nota** · entrega em **15 dias corridos** após a última aula

<!--
Último slide do deck (e link direto no sumário do site: /gdbd/trabalho-final).
Confirme a data exata de entrega e o canal (Classroom) com a turma.
-->

---

## Trabalho final: o que fazer

- Cada grupo recebe **um clube** da Premier League 2024/25 pela matrícula do 1º integrante:
  `python3 tools/trabalho/trabalho.py clube <matricula>`
- Na **sua conta AWS**: monte **Raw → Clean → Curated** (Parquet particionado por `year`/`month`).
- Responda **8 perguntas** com Athena sobre o seu clube.
- Meça o *Data scanned* da mesma consulta em CSV e em Parquet particionado e explique a diferença.

| | |
|---|---|
| **Vale** | **100% da nota** (aprovação com nota ≥ 6,0) |
| **Quem** | individual ou grupo de até 3, você escolhe |
| **Prazo** | **15 dias corridos** após a última aula |
| **Custo** | de centavos a ~US$ 1 se limpar no mesmo dia |

Enunciado completo e critérios: [`avaliacao/trabalho.md`](https://github.com/obernardocosta/big-data/blob/main/disciplinas/gdbd/avaliacao/trabalho.md)

---

## Trabalho final: como entregar

1. Copie o [`trabalho-modelo/`](https://github.com/obernardocosta/big-data/tree/main/disciplinas/gdbd/avaliacao/trabalho-modelo)
   e preencha `entrega.json`, `README.md` e `consultas.sql`.
2. Rode a autoconferência (formato e estrutura, **não** diz se as respostas estão certas):
   `python3 tools/trabalho/trabalho.py validar <pasta> --disciplina gdbd`
3. **Limpe os recursos** da sua conta (buckets, tabelas, jobs, crawlers).
4. Entregue a pasta (zip ou repositório) em até **15 dias corridos** após a última aula.

Dúvidas ou problemas: [abra uma issue](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml).

### Bom trabalho!

<!-- Confirme a data exata (15 dias corridos) e o canal (Classroom). -->
