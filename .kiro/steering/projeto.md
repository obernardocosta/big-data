# Projeto: Material de Big Data (GDBD + PDN)

## O que é este repositório

Material versionado e programável das duas disciplinas de Big Data ministradas
pelo Bernardo Costa:

- **GDBD** — Gerenciamento de Dados para Big Data
- **PDN** — Processamento de Big Data na Nuvem

O material nasceu de apresentações em Google Slides e está sendo migrado para
[Slidev](https://sli.dev) (slides em Markdown) para ficar:

- **Programável**: slides e labs escritos como texto/código.
- **Versionado**: histórico no Git, com o porquê de cada mudança.
- **Fácil de atualizar**: editar Markdown e republicar.
- **Fácil de distribuir**: publicado via GitHub Pages, um site por disciplina.

## Estrutura (monorepo)

```
disciplinas/
  gdbd/   -> slides/ labs/ avaliacao/ agenda/ export/
  pdn/    -> mesma estrutura
tools/
  notas/  -> script de cálculo de notas (CSV)
.kiro/
  steering/ -> este diretório (memória + convenções, carregado sempre)
  skills/   -> "como fazer" replicável (criar aula, criar lab)
_fonte/     -> PDFs originais exportados dos Slides (referência, fora do build)
```

## Publicação

- Um único GitHub Pages, subpastas por disciplina:
  - `/gdbd/` -> Gerenciamento de Dados para Big Data
  - `/pdn/`  -> Processamento de Big Data na Nuvem
- `npm run build:all` gera `dist/gdbd` e `dist/pdn`.

## Decisões tomadas (histórico vivo)

- **2026-10**: Migração de Google Slides -> Slidev. Monorepo em vez de dois
  repositórios, para compartilhar skills, steering e templates de lab.
- **2026-10**: Avaliação **sem quiz** (o acesso ao Kahoot foi perdido). A nota
  é composta por presença + participação nos labs + trabalho/entrega, calculada
  a partir de um CSV versionado por um script (`npm run notas`).
- **2026-10**: Todo lab precisa de um `dry-run.sh` que valida o ambiente
  **sem gastar** (credenciais, região, quota, permissões) antes da aula.

## Contexto do instrutor (feedback a tratar)

Feedback recebido de turmas anteriores, que guia as convenções deste repo:

1. Labs ocupavam muito tempo e às vezes falhavam (quota, config, passo a passo).
   -> Daí o `dry-run.sh` obrigatório e o `troubleshooting.md` por lab.
2. Faltava conectar a prática aos conceitos durante o lab.
   -> Todo lab começa com "Por que estamos fazendo isso" e "O que você aprende".
3. Atrasos no início da aula.
   -> A agenda tem timeboxes e, a partir da aula 2, os primeiros 30 min são
      para dúvidas / terminar atividades, enquanto os alunos chegam.
4. Materiais disponibilizados tarde no Classroom.
   -> Publicação automática: o aluno sempre tem a versão atual pelo site.
