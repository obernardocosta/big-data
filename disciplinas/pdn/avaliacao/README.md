# Avaliação — PDN

A avaliação segue o **mesmo modelo da GDBD**: sem quiz, nota final como média
ponderada de **presença + participação + trabalho**, lançada em CSV versionado e
calculada pelo script `tools/notas/calcular-notas.mjs`.

## Componentes e pesos

| Componente | Escala no CSV | Peso |
|---|---|---|
| **Presença** | 0 a 100 (%) | 20% |
| **Participação** (labs) | 0 a 10 | 30% |
| **Trabalho** (entrega final) | 0 a 10 | 50% |

Média para aprovação: **6,0**. Os pesos ficam no topo do script e valem para as
duas disciplinas; ajuste lá se a turma usar outra combinação.

## Como lançar e calcular

Crie um CSV em `notas/` (cabeçalho fixo: `matricula,nome,presenca,participacao,trabalho`),
um arquivo por turma/semestre, e rode da raiz do repositório:

```bash
npm run notas -- disciplinas/pdn/avaliacao/notas/turma-exemplo.csv
```

Use `notas/turma-exemplo.csv` como modelo. Os detalhes do fluxo (validações,
decimal com vírgula, linhas ignoradas) estão em
[`../../gdbd/avaliacao/README.md`](../../gdbd/avaliacao/README.md).
