# CHECKPOINT — Migração GDBD/PDN para Slidev

> Retome daqui pelo Kiro CLI. Este arquivo descreve o que já foi feito, o que
> falta, e os comandos prontos para continuar. Atualizado em 2026-10-29 (Aula 2).

## Objetivo do projeto

Transformar as apresentações de Google Slides das duas disciplinas (GDBD e PDN)
em material **programável, versionado e fácil de distribuir** usando Slidev,
tratando o feedback recebido (labs mal testados, prática desconectada de
conceito, atrasos, material disponibilizado tarde).

Decisões já tomadas (ver `.kiro/steering/projeto.md`):
- Monorepo, publicação em GitHub Pages por subpasta (`/gdbd`, `/pdn`).
- Avaliação **sem quiz**: nota = presença + participação em labs + trabalho,
  calculada de um CSV versionado por `npm run notas`.
- Todo lab tem `dry-run.sh` read-only que valida o ambiente sem gastar.

## Ambiente (já validado)

- Node v22.18.0, npm 10.9.3, git 2.47.0 — OK.
- Slidev instalado (`npm install` concluído, 677 pacotes).
- AWS CLI v2.13.17 instalada (sem credencial configurada nesta máquina).
- `pypdf` instalado (usado para extrair o texto do PDF original).

## O que JÁ está pronto ✅

### Configuração e convenções
- `package.json` com scripts: `gdbd:dev`, `gdbd:build`, `gdbd:export`,
  `pdn:*`, `build:all`, `notas`.
- `.gitignore` (ignora node_modules, dist, .slidev, PDFs).
- `.kiro/steering/`: `projeto.md`, `didatica.md`, `labs.md` (memória + convenções
  do Kiro, carregadas sempre).
- `.kiro/skills/`: `criar-aula/SKILL.md`, `criar-lab/SKILL.md`.

### Conteúdo de origem
- `_fonte/gdbd_extraido.txt`: texto dos 179 slides originais do GDBD, extraído.

### GDBD — Aula 1 (fatia vertical, VALIDADA com build OK)
- `disciplinas/gdbd/slides/index.md`: deck principal.
- `disciplinas/gdbd/slides/aula-01-catalogo.md`: Aula 1 completa migrada
  (slides 1–60: intro, estudo de caso, catálogo de dados, Hive Metastore →
  Glue Data Catalog, open source vs AWS, labs). **`slidev build` passou (exit 0).**
- `disciplinas/gdbd/labs/lab-01-glue-catalog/`: README, passo-a-passo,
  dry-run.sh (sintaxe e execução validadas), troubleshooting.
- `disciplinas/gdbd/labs/lab-02-glue-crawler/`: README, passo-a-passo,
  dry-run.sh (sintaxe validada) e **troubleshooting.md** ✅.

### Fatia da Aula 1 — concluída ✅ (2026-10-29)
- `disciplinas/gdbd/labs/lab-02-glue-crawler/troubleshooting.md`: erros comuns
  (role/PassRole, Crawler sem tabela, schema update, região) + plano B.
- Sistema de notas (sem quiz):
  - `tools/notas/calcular-notas.mjs`: lê o CSV, valida colunas/faixas e calcula
    a nota final (presença 20% + participação 30% + trabalho 50%, aprovação 6,0).
    **Executado com a planilha de exemplo (exit 0).**
  - `disciplinas/gdbd/avaliacao/notas/turma-exemplo.csv`: modelo de planilha.
  - `disciplinas/gdbd/avaliacao/README.md`: fluxo de lançamento e cálculo.
- `disciplinas/gdbd/agenda/plano-de-aula.md`: timeboxes da Aula 1, regra de
  pontualidade e bloco de 30 min de dúvidas a partir da Aula 2.
- `README.md` na raiz: porta de entrada para aluno e instrutor.
- **`slidev build` revalidado após as mudanças (exit 0).**

### GDBD — Aula 2 (Athena/Presto + particionamento) ✅ (2026-10-29)
- `disciplinas/gdbd/slides/aula-02-athena.md`: Aula 2 migrada (slides 61–91:
  bloco dos 30 min, PrestoDB, arquitetura Coordinator/Worker, 3 opções na AWS,
  Amazon Athena, Athena vs EMR, particionamento no S3). Importada no `index.md`.
- `disciplinas/gdbd/labs/lab-03-athena-queries/`: README, passo-a-passo,
  dry-run.sh (executado sem credencial: reporta o que falta e sai 1) e
  troubleshooting.md.
- `disciplinas/gdbd/labs/lab-04-particionamento/`: README, passo-a-passo,
  dry-run.sh (sintaxe + execução validadas) e troubleshooting.md.
- **`slidev build` com a Aula 2 passou (exit 0).**

## O que FALTA ⬜

### Curtíssimo prazo (terminar a fatia da Aula 1) — CONCLUÍDO ✅
1. [x] `disciplinas/gdbd/labs/lab-02-glue-crawler/troubleshooting.md`.
2. [x] Sistema de notas (`calcular-notas.mjs` + `turma-exemplo.csv` + `avaliacao/README.md`).
3. [x] `disciplinas/gdbd/agenda/plano-de-aula.md`.
4. [x] `README.md` na raiz.

### Migração das aulas — GDBD COMPLETA ✅
- [x] **Aula 2** — Athena/Presto + particionamento (Labs 03 e 04).
- [x] **Aula 3** — Processamento: AWS Glue Job / Spark serverless (Lab 05).
- [x] **Aula 4** — Orquestração: Airflow → MWAA / Step Functions (conceitual).
- [x] **Aula 5** — Amazon EMR (Lab 06, custo ~US$ 1, dry-run reforçado).
- [x] **Aula 6** — Data Lake 3 camadas (Lab 07, lab final).
- GDBD: 6 aulas, 7 labs. `slidev build` passa (exit 0).

### Disciplina PDN — REESCRITA com material real ✅ (2026-10-29)
- Material real extraído dos PDFs das turmas 2024.02/2025.01 para
  `_fonte/pdn_*.txt`. Tema real = **EMR Serverless + Machine Learning (SageMaker)
  + custos**, NÃO streaming (a 1ª versão com Kinesis foi substituída).
- Slides (`disciplinas/pdn/slides/`):
  - `aula-01-emr-serverless.md` — EMR Serverless (RuntimeRole por job, preço/TCO)
    + Trabalho/Seminário.
  - `aula-02-sagemaker.md` — ML na AWS, SageMaker, pipeline (Batch vs real time),
    extra de custos (DynamoDB vs S3 vs Firehose).
  - `aula-03-labs.md` — dia de labs (sábado).
- Labs: `lab-01-emr-serverless/` e `lab-02-sagemaker/` (4 arquivos cada; dry-runs
  read-only validados; destacam custo e limpeza — Endpoint do SageMaker é o
  maior risco). O lab de streaming (Kinesis) foi removido.
- `agenda/plano-de-aula.md` e `avaliacao/` ajustados.
- `slidev build` da PDN passa; `npm run build:all` gera `dist/gdbd` e `dist/pdn`.

### Grade horária real aplicada ✅ (2026-10-29)
- **GDBD**: 6 aulas = 4× 18h–22h (ter/qui, teoria+prática) + 2× sábado 8h–13h
  (labs pesados: EMR e Data Lake). Refletido no plano-de-aula da GDBD.
- **PDN**: 3 aulas = 2× 18h–22h (ter/qui) + 1× sábado 8h–13h (dia de labs).
  Refletido no plano-de-aula da PDN.

### Página inicial estilo "sumário de livro" ✅ (2026-10-29)
- `site/index.html` reescrita: lista as duas disciplinas com cada aula linkando
  **direto ao capítulo** (`/gdbd/aula-N`, `/pdn/aula-N`), sem passar por todos
  os slides. Habilitado por `routeAlias: aula-N` no slide de abertura de cada
  aula (deep link resolvido via SPA + `404.html` do Slidev no Pages).

### Próximos passos sugeridos
- [ ] Exportar o PDF original do PDN para `_fonte/` e migrar as Aulas 2+.
- [ ] (Opcional) Skill `criar-avaliacao` formalizando o fluxo de notas.

### Depois de validar com você
6. [ ] (Opcional) Skill `criar-avaliacao` formalizando o fluxo de notas.
7. [ ] Exportar o PDF original do PDN para `_fonte/` e migrar as Aulas 2+ da PDN.

### Publicação (GitHub + Pages) — CONCLUÍDO ✅ (2026-10-29)
8. [x] `git init` + commit inicial + repo remoto `obernardocosta/big-data`
   (público) criado via `gh` e push de `main`.
9. [x] Workflow de GitHub Actions publicando no Pages. **Site no ar:**
   - Raiz: https://obernardocosta.github.io/big-data/ (HTTP 200)
   - GDBD: https://obernardocosta.github.io/big-data/gdbd/ (HTTP 200)
   - PDN:  https://obernardocosta.github.io/big-data/pdn/ (build automático quando a disciplina existir)

### Só com você presente (NÃO fazer sozinho)
10. [ ] Rodar os `dry-run.sh` com credencial AWS real e executar um lab ponta a
    ponta para validar (custo real envolvido).

## Notas de publicação

- O repo é **público** (Pages em repo privado exigiria plano pago).
- O token do `gh` precisou do escopo **`workflow`** (`gh auth refresh -s workflow`)
  e do credential helper (`gh auth setup-git`) para o push HTTPS funcionar.
- O deploy roda a cada push em `main`. O build do PDN é condicional: ativa
  sozinho quando `disciplinas/pdn/slides/index.md` existir.
- Avisos não-bloqueantes do Actions: deprecação do Node 20 nas actions e
  migração futura do runner `ubuntu-latest`. Nada quebra hoje.
- **2026-10-29**: o `node_modules/` foi perdido numa cópia de pasta (ele é
  gitignored e não acompanha cópia). Restaurado com `npm ci`. Para buildar
  localmente use `npx slidev build ...` **com as dependências instaladas**; se
  o npx tentar baixar `slidev@*` do registry e der 404, é sinal de que o
  `node_modules` sumiu — rode `npm ci` de novo.

## Como retomar pelo Kiro CLI

Peça algo como:
- "Continue o CHECKPOINT.md a partir do item 1" — para fechar a fatia da Aula 1.
- Para criar labs/aulas, as skills já guiam: `criar-aula` e `criar-lab`.

## Comandos úteis

```bash
# pré-visualizar os slides da GDBD no navegador
npm run gdbd:dev

# validar que os slides compilam
npx slidev build disciplinas/gdbd/slides/index.md --out /tmp/check && rm -rf /tmp/check

# validar o ambiente de um lab (read-only, sem custo)
bash disciplinas/gdbd/labs/lab-01-glue-catalog/dry-run.sh

# (quando existir) calcular notas
npm run notas
```

## Notas de estado

- A fatia da Aula 1 está **completa**: labs 01 e 02 com os 4 arquivos cada,
  sistema de notas, agenda e README da raiz.
- O `slidev build` da Aula 1 passou com sucesso (exit 0) antes e depois das
  mudanças desta sessão, renderizando inclusive os diagramas Mermaid.
- O `calcular-notas.mjs` foi executado com `turma-exemplo.csv`: calcula e
  classifica corretamente (exit 0).
- O `dry-run.sh` do lab-01 foi executado nesta máquina: sem credencial AWS, ele
  reporta corretamente o que falta e sai com código 1 (comportamento esperado).
  Os dry-runs NÃO foram rodados contra uma conta AWS real (ver item 10).
- Nada foi versionado em git ainda e nada foi publicado. Nenhum recurso AWS foi
  criado. Nenhuma credencial foi usada.
