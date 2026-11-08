# Avaliação — PDN

A avaliação segue o **mesmo modelo da GDBD**: sem quiz, nota final como média
ponderada de **presença + participação + trabalho**, lançada em CSV e calculada
por script. Notas, CSVs das turmas e correção ficam no repositório privado
(veja o fim deste arquivo).

## Componentes e pesos

| Componente | Escala no CSV | Peso |
|---|---|---|
| **Presença** | 0 a 100 (%) | 20% |
| **Participação** (labs) | 0 a 10 | 30% |
| **Trabalho** (entrega final) | 0 a 10 | 50% |

Média para aprovação: **6,0**. Os pesos valem para as duas disciplinas.

## O trabalho final

O componente **Trabalho** (50%) é o **Pipeline e custo do meu clube**: batch no
EMR Serverless + streaming com Kinesis/Firehose + um ADR de arquitetura com custo.
Individual ou em grupo de até 3, na conta AWS do próprio aluno. SageMaker é
**bônus opcional** (+1,0). Corrigido em boa parte por script (6,0 automáticos +
4,0 por rubrica).

- Enunciado para o aluno: [`trabalho.md`](trabalho.md)
- Modelo de entrega: [`trabalho-modelo/`](trabalho-modelo/)
- Correção (instrutor): repositório privado, veja o fim deste arquivo

## Onde ficam as notas e a correção (privado)

Notas, CSVs das turmas, entregas dos alunos e o corretor do trabalho (com
gabarito) ficam no repositório privado `obernardocosta/big-data-privado` (privado). O fluxo é o mesmo da
[GDBD](../../gdbd/avaliacao/README.md).
