# Material de Big Data — GDBD + PDN

Material versionado e programável das duas disciplinas de Big Data ministradas
por Bernardo Costa:

- **GDBD** — Gerenciamento de Dados para Big Data
- **PDN** — Processamento de Big Data na Nuvem

Os slides são escritos em Markdown com [Slidev](https://sli.dev) e os labs são
texto + scripts. Tudo fica versionado no Git e é publicado como site, de modo
que **o aluno sempre tem a versão mais atual** do material.

## Dados dos labs

Os datasets usados nos labs ficam em [obernardocosta/data](https://github.com/obernardocosta/data) (cópia raw, licença CC0), para os labs não dependerem de fontes de terceiros.

## Para o aluno

- Os slides de cada disciplina são publicados como um site (um por disciplina).
- Cada aula tem **labs práticos** com passo a passo detalhado e explicação do
  *porquê* de cada etapa — não é só "clique aqui".
- A avaliação é **sem quiz**: a nota final é **100% o trabalho final**; os labs
  são o treino. O critério está em [`disciplinas/gdbd/avaliacao/`](disciplinas/gdbd/avaliacao/).

## Para o instrutor

### Pré-requisitos

- Node.js 18+ (testado com v22) e npm.
- Para rodar os labs de verdade: AWS CLI v2 e uma conta AWS com usuário IAM.

### Instalar

```bash
npm install
```

### Slides

```bash
npm run gdbd:dev      # pré-visualiza a GDBD no navegador
npm run gdbd:build    # gera o site estático em dist/gdbd
npm run gdbd:export   # exporta a GDBD em PDF

# (a disciplina PDN usa os mesmos scripts com prefixo pdn:)
npm run build:all     # gera dist/gdbd e dist/pdn
```

Validar que os slides compilam sem abrir o navegador:

```bash
npx slidev build disciplinas/gdbd/slides/index.md --out /tmp/check && rm -rf /tmp/check
```

### Labs

Cada lab tem quatro arquivos: `README.md` (objetivo, conceito, pré-requisitos,
custo, tempo), `passo-a-passo.md`, `dry-run.sh` e `troubleshooting.md`.

**Regra de ouro:** rode o `dry-run.sh` do lab **na véspera da aula**. Ele valida
o ambiente (credencial, região, usuário IAM, permissões) com chamadas
**somente-leitura** — não cria nada que gere custo.

```bash
bash disciplinas/gdbd/labs/lab-01-glue-catalog/dry-run.sh
```

### Acesso da turma ao SageMaker (Lab C da PDN)

Conta AWS nova vem com quota 0 de treino no SageMaker. Para a turma usar a sua
conta com acesso temporário, isolado e barato:

```bash
tools/turma/turma.sh criar --turma pdn-2026-2 --alunos 30 --expira 2026-12-15 --email voce@exemplo.com
tools/turma/turma.sh limpar --turma pdn-2026-2
```

Guia completo em [`tools/turma/README.md`](tools/turma/README.md).

### Notas, turmas e correção (repositório privado)

Dados de aluno e o gabarito do trabalho **não ficam aqui**: este repositório é
público. Eles vivem no repositório privado `obernardocosta/big-data-privado` (privado)
(notas e CSVs das turmas, `npm run notas`, entregas e corretor do trabalho final).
Clone os dois lado a lado. Os critérios estão em
[`disciplinas/gdbd/avaliacao/README.md`](disciplinas/gdbd/avaliacao/README.md).

### Trabalho final

Cada disciplina tem um trabalho final (100% da nota), individual ou em grupo de
até 3, feito na conta AWS do aluno. Cada grupo recebe um clube da Premier League
pela matrícula, então as respostas mudam de grupo para grupo e a parte objetiva
é corrigida por script (no repositório privado).

```bash
npm run trabalho -- clube 2024001                                  # clube do grupo
npm run trabalho -- validar minha-entrega --disciplina gdbd        # autoconferência do aluno
```

Enunciados: [GDBD](disciplinas/gdbd/avaliacao/trabalho.md) ·
[PDN](disciplinas/pdn/avaliacao/trabalho.md). Guia em
[`tools/trabalho/README.md`](tools/trabalho/README.md).

## Estrutura do repositório

```
disciplinas/
  gdbd/
    slides/      # decks Slidev (index.md importa cada aula)
    labs/        # labs práticos (README, passo a passo, dry-run, troubleshooting)
    avaliacao/   # critérios de nota, enunciado e modelo do trabalho final
    agenda/      # plano de aula com timeboxes
    export/      # PDFs exportados (gerados)
  pdn/           # mesma estrutura (a criar)
tools/
  trabalho/      # clube do grupo e autoconferência do trabalho final (público)
.kiro/
  steering/      # memória e convenções do projeto (carregadas sempre)
  skills/        # "como fazer" replicável (criar-aula, criar-lab)
_fonte/          # material original exportado dos Slides (referência, fora do build)
```

## Convenções

As decisões de projeto e as convenções de didática e de labs estão em
[`.kiro/steering/`](.kiro/steering/). Os guias passo a passo para adicionar
conteúdo estão em [`.kiro/skills/`](.kiro/skills/) (`criar-aula` e `criar-lab`).

## Estado da migração

O andamento da migração (o que está pronto e o que falta) é acompanhado em
[`CHECKPOINT.md`](CHECKPOINT.md).
