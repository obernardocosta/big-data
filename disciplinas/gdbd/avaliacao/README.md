# Avaliação — GDBD

A avaliação desta disciplina é **sem quiz**. A nota final é a média ponderada de
três componentes, lançados num CSV versionado e calculados por um script.

## Componentes e pesos

| Componente | O que é | Escala no CSV | Peso |
|---|---|---|---|
| **Presença** | % de presença nas aulas | 0 a 100 | 20% |
| **Participação** | engajamento e entrega nos labs | 0 a 10 | 30% |
| **Trabalho** | trabalho / entrega final | 0 a 10 | 50% |

A presença (em %) é normalizada para a escala 0–10 antes de ponderar. A **média
para aprovação é 6,0**. Os pesos e a média ficam no topo de
`tools/notas/calcular-notas.mjs` — altere ali se a turma usar outra combinação.

## Como lançar as notas

Edite um CSV na pasta `notas/`. O cabeçalho é fixo:

```csv
matricula,nome,presenca,participacao,trabalho
2024001,Ana Souza,100,9.0,8.5
```

- Uma linha por aluno.
- `presenca` em % (0–100); `participacao` e `trabalho` em nota (0–10).
- Aceita vírgula ou ponto como separador decimal.
- Linhas em branco e linhas iniciadas por `#` são ignoradas.

Use `notas/turma-exemplo.csv` como modelo. Crie um arquivo por turma/semestre
(ex.: `notas/2026-2.csv`) — assim o histórico fica versionado no Git.

## Como calcular

Da raiz do repositório:

```bash
# usa a planilha de exemplo
npm run notas

# ou aponte para a sua planilha
npm run notas -- disciplinas/gdbd/avaliacao/notas/2026-2.csv
```

O script valida o CSV (colunas obrigatórias, faixas dos valores), imprime a
tabela com a nota final e a situação (Aprovado/Reprovado) de cada aluno, e um
resumo da turma ao final. Se algum valor estiver fora da faixa ou faltar coluna,
ele aponta a linha com o problema e sai com código diferente de zero.

## Por que assim

A decisão de abandonar o quiz (o acesso ao Kahoot foi perdido) está registrada
no steering do projeto. Lançar notas em CSV versionado deixa o critério
transparente, reproduzível e auditável: a nota de qualquer aluno pode ser
recalculada a partir do mesmo arquivo, e o histórico de alterações fica no Git.
