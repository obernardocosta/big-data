# Material de Big Data — GDBD + PDN

Material versionado e programável das duas disciplinas de Big Data ministradas
por Bernardo Costa:

- **GDBD** — Gerenciamento de Dados para Big Data
- **PDN** — Processamento de Big Data na Nuvem

Os slides são escritos em Markdown com [Slidev](https://sli.dev) e os labs são
texto + scripts. Tudo fica versionado no Git e é publicado como site, de modo
que **o aluno sempre tem a versão mais atual** do material.

## Para o aluno

- Os slides de cada disciplina são publicados como um site (um por disciplina).
- Cada aula tem **labs práticos** com passo a passo detalhado e explicação do
  *porquê* de cada etapa — não é só "clique aqui".
- A avaliação é **sem quiz**: a nota vem de presença + participação nos labs +
  trabalho. O critério está em [`disciplinas/gdbd/avaliacao/`](disciplinas/gdbd/avaliacao/).

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

### Notas

Lance as notas num CSV versionado e calcule a nota final:

```bash
npm run notas                                              # planilha de exemplo
npm run notas -- disciplinas/gdbd/avaliacao/notas/2026-2.csv
```

Detalhes do fluxo e dos pesos em
[`disciplinas/gdbd/avaliacao/README.md`](disciplinas/gdbd/avaliacao/README.md).

## Estrutura do repositório

```
disciplinas/
  gdbd/
    slides/      # decks Slidev (index.md importa cada aula)
    labs/        # labs práticos (README, passo a passo, dry-run, troubleshooting)
    avaliacao/   # critério de notas + planilhas CSV
    agenda/      # plano de aula com timeboxes
    export/      # PDFs exportados (gerados)
  pdn/           # mesma estrutura (a criar)
tools/
  notas/         # script de cálculo de notas a partir do CSV
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
