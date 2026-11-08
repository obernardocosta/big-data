# tools/trabalho — clube do grupo e autoconferência (público)

Serve às duas disciplinas. Enunciados dos alunos:
[GDBD](../../disciplinas/gdbd/avaliacao/trabalho.md) ·
[PDN](../../disciplinas/pdn/avaliacao/trabalho.md).

Só precisa de `python3` (biblioteca padrão). Os dados vêm do
[repo de dados](https://github.com/obernardocosta/data/tree/main/football);
use `--dados arquivo.json` para trabalhar offline.

## A ideia

Cada grupo (1 a 3 pessoas) trabalha com **um clube** da Premier League 2024/25,
escolhido pela **matrícula do primeiro integrante**:
`clubes ordenados[ matrícula (só dígitos) mod 20 ]`. Como o dado é fixo, as
respostas de cada clube são calculáveis, então a parte objetiva se corrige por
script e as respostas mudam de grupo para grupo.

## Comandos (alunos)

```bash
# qual é o meu clube
python3 tools/trabalho/trabalho.py clube 2024001

# autoconferência: formato e estrutura da entrega
# (NÃO revela se as respostas estão certas)
python3 tools/trabalho/trabalho.py validar minha-entrega --disciplina gdbd
```

## Correção

A correção (gabarito e nota) **não fica neste repositório**: vive no repositório
privado `big-data-privado`, que reaproveita as checagens deste arquivo.
