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
  trabalho/ -> clube do grupo e autoconferência do trabalho final (público)
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
  era composta por presença + participação + trabalho; **a partir de 2026-11 a
  nota final é 100% o trabalho** (ver decisão abaixo), calculada de um CSV por um
  script (`npm run notas`, no repo privado).
- **2026-11**: Tudo que tem **dado de aluno ou gabarito** vive no repositório
  **privado** `obernardocosta/big-data-privado` (clonado ao lado deste):
  notas e CSVs das turmas, `npm run notas`, entregas e o corretor do trabalho
  final. Este repo é público: **nunca** commitar CSV de turma, nota, entrega de
  aluno nem gabarito aqui. O público guarda critérios, enunciados e modelos.
- **2026-10**: Todo lab precisa de um `dry-run.sh` que valida o ambiente
  **sem gastar** (credenciais, região, quota, permissões) antes da aula.
- **2026-11**: **Nota = 100% trabalho final** (presença e participação não entram
  no cálculo; labs são o treino, não valem nota; aprovação com nota >= 6,0).
  Isso deve estar explícito nos slides da turma, nos enunciados e nas agendas.
- **2026-11**: Trabalho final (100% da nota) definido nas duas disciplinas:
  individual ou grupo de até 3 (aluno escolhe), na **conta AWS do próprio
  aluno**. Cada grupo recebe um clube da Premier League pela matrícula do 1º
  integrante; respostas diferentes por clube permitem correção por script
  (6,0 automáticos + 4,0 por rubrica manual). O **corretor com o gabarito é
  privado** (repo privado, ver decisão abaixo; este repo é público);
  `tools/trabalho` expõe só `clube` e `validar` para o aluno. GDBD = Data Lake
  do meu clube; PDN = Pipeline e custo do meu clube (EMR Serverless + Kinesis/
  Firehose + ADR). **SageMaker é opcional** (bônus +1,0). Prazo: 10 dias após a
  última aula. Contas novas podem ter o Glue bloqueado: CTAS no Athena é rota aceita.

## Boas práticas de Git (várias sessões ao mesmo tempo)

Várias sessões (e pessoas) podem editar este repositório ao mesmo tempo, cada uma
em arquivos diferentes. Por isso:

- Antes de dar `git push` em `main`, rode `git fetch` e, se houver commits novos,
  `git pull --rebase origin main`; só então faça o push. Nunca force push.
- Se o push for rejeitado ("fetch first" / "non-fast-forward"), faça o
  `pull --rebase` e tente de novo; não descarte nem sobrescreva commits dos outros.
- Faça commits pequenos e por assunto, e adicione arquivos específicos (evite
  `git add -A` quando houver mudança de outra sessão no working tree).
- Antes de editar, confira `git status` e `git log origin/main` para ver o que
  mudou; não reverta alterações que você não fez.
- Se houver conflito de rebase, resolva preservando as duas mudanças e registre
  no commit o que foi combinado.

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
