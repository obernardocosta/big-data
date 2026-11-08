# Avaliação — GDBD

A avaliação desta disciplina é **sem quiz**. A nota final é a média ponderada de
três componentes, lançados num CSV e calculados por um script. Planilhas, notas
e correção ficam no repositório **privado** (veja o fim deste arquivo).

## Componentes e pesos

| Componente | O que é | Escala no CSV | Peso |
|---|---|---|---|
| **Presença** | % de presença nas aulas | 0 a 100 | 20% |
| **Participação** | engajamento e entrega nos labs | 0 a 10 | 30% |
| **Trabalho** | trabalho / entrega final | 0 a 10 | 50% |

A presença (em %) é normalizada para a escala 0–10 antes de ponderar. A **média
para aprovação é 6,0**.

## O trabalho final

O componente **Trabalho** (50%) é o **Data Lake do meu clube**: individual ou em
grupo de até 3, na conta AWS do próprio aluno, corrigido em boa parte por script
(6,0 automáticos + 4,0 por rubrica).

- Enunciado para o aluno: [`trabalho.md`](trabalho.md)
- Modelo de entrega: [`trabalho-modelo/`](trabalho-modelo/)
- Correção (instrutor): repositório privado, veja o fim deste arquivo

## Onde ficam as notas e a correção (privado)

Notas, CSVs das turmas, entregas dos alunos e o corretor do trabalho (com
gabarito) ficam no repositório privado `obernardocosta/big-data-privado` (privado), para não expor dados de aluno nem
as respostas. Lá estão o passo a passo de lançar notas (`npm run notas`) e de
corrigir o trabalho.

## Por que assim

A decisão de abandonar o quiz (o acesso ao Kahoot foi perdido) está registrada
no steering do projeto. Lançar notas em CSV versionado deixa o critério
transparente, reproduzível e auditável: a nota de qualquer aluno pode ser
recalculada a partir do mesmo arquivo, e o histórico fica no Git (no repositório
privado, porque tem dado pessoal).
