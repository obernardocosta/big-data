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
- Avaliação **sem quiz**: nota final = **100% trabalho final** (desde 2026-11;
  antes era presença + participação + trabalho), calculada de um CSV por
  `npm run notas` (repo privado).
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
  - (movido em 2026-11-08 para o repo privado `big-data-privado`) `calcular-notas.mjs` (hoje `notas/fechamento.mjs`): lê o CSV, valida colunas/faixas e calcula
    a nota final (hoje 100% trabalho; na época: presença 20% + participação 30% + trabalho 50%; aprovação 6,0).
    **Executado com a planilha de exemplo (exit 0).**
  - `turmas/gdbd/turma-exemplo.csv` (repo privado): modelo de planilha (presença por aula + nota).
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

### Grade horária real aplicada ✅ (2026-10-29, corrigida)
- As aulas seguem a **sequência da semana**: **terça → quinta → sábado**,
  intercaladas (NÃO agrupadas por tipo). Noturnas começam **18h30** (não 18h):
  **18h30–22h** (~3h30); sábado **8h–13h** (~5h).
- **GDBD** (6 aulas, 2 semanas): S1 ter(A1)/qui(A2)/sáb(A3) · S2 ter(A4)/qui(A5)/sáb(A6).
  Sábados = Aulas 3 e 6. Obs.: o Lab 06 (EMR) cai numa **quinta (3h30)** — dry-run
  reforçado + parada segura rígida.
- **PDN** (3 aulas, 1 semana): ter(A1)/qui(A2)/sáb(A3). Sábado (A3) = dia de labs.
- Timeboxes dos planos recalculados para 18h30–22h e para a cadência correta.

### Deep links por aula no Pages ✅ (2026-10-29)
- `routeAlias: aula-N` em cada slide de abertura; página inicial (`site/index.html`)
  é um **sumário** com link direto por aula.
- O Pages não faz fallback de SPA em subpasta — por isso o workflow agora **gera
  um arquivo físico por alias** (`<deck>/aula-N/index.html`, cópia do `404.html`
  do deck = a SPA). Os aliases são lidos dos `.md` no build.
- Verificado AO VIVO: `/big-data/{gdbd,pdn}/aula-N/` → HTTP 200 servindo a SPA
  correta. Sumário em https://obernardocosta.github.io/big-data/.

### Disciplina PDN — REPLANEJADA com o instrutor ✅ (2026-10-29)
Fio condutor: alunos chegam sabendo Spark/Spark Streaming → PDN mostra isso na
nuvem (EMR Serverless), **streaming gerenciado (protagonista)** e ML (SageMaker).
Material real dos PDFs em `_fonte/pdn_*.txt`. **Seminário removido** a pedido.
- Grade real: ter(A1) · qui(A2) · sáb(A3); noturnas **18h30–22h**, sábado 8h–13h.
- Slides (refino pedagógico: objetivos + roteiro cronometrado + "o que você leva"):
  - `aula-01-emr-serverless.md` — EMR Serverless (RuntimeRole, preço/TCO).
  - `aula-02-streaming.md` — **Streaming na AWS** (Kinesis + Firehose) + custo
    (DynamoDB vs S3 vs Firehose). Flink só citado.
  - `aula-03-sagemaker.md` — SageMaker (Batch vs Endpoint) + dia de labs.
- Labs construídos **do zero**, dados **públicos e atuais** (openfootball
  Premier League 2024/25, JSON sem API key):
  - `lab-01-emr-serverless` — PySpark batch sobre jogos reais.
  - `lab-02-streaming` — produtor → Kinesis → Firehose → S3 **e** Spark
    Structured Streaming lendo o S3 em micro-batches (opção (b): file source,
    sem conector Kinesis — mais robusto em aula; conector Kinesis fica como extra).
  - `lab-03-sagemaker` — treino + deploy (Batch recomendado; Endpoint = risco de custo).
  - Cada lab: README, passo-a-passo, dry-run read-only (validados), troubleshooting.
- `routeAlias` atualizado; `slidev build` da PDN passa (exit 0).

### Refino pedagógico (GDBD + PDN) ✅ (2026-10-29)
- PDN: 3 aulas no padrão objetivos→roteiro cronometrado→teoria→prática→"o que você leva".
- GDBD: as 6 aulas refinadas no mesmo padrão — cada uma abre com **objetivos de
  aprendizagem** e um **roteiro com timeboxes** no horário real (terça/quinta
  18h30–22h ~3h30; sábado 8h–13h ~5h), e fecha com **"o que você leva"** +
  gancho para a próxima aula. Conteúdo técnico preservado; `slidev build` passa.

### Navegação "voltar ao sumário" nos slides ✅ (2026-10-29)
- `global-bottom.vue` em cada deck (gdbd e pdn): botão fixo discreto "⌂ Início"
  no canto inferior, em todos os slides, linkando para o sumário. O destino é
  derivado de `import.meta.env.BASE_URL` (ex.: `/big-data/gdbd/` → `/big-data/`),
  então funciona em produção e em dev local. Oculto na impressão/export PDF.

### Ideias registradas para depois (na ordem combinada)
- Todas concluídas ✅ (sublinks de labs e botão voltar-ao-início implementados).

### Refactor de distribuição de tempo da GDBD — Opção 1 ✅ (2026-10-29)
Diagnóstico: as aulas mais densas (1, 2 com 2 labs; 5 com o lab caro de EMR) caem
em **terça/quinta (3h30)**, e os **sábados (5h)** ficaram com as mais leves (3, 6)
— carga invertida vs tempo disponível.
Refactor (mantendo a ordem didática): roteiros recalibrados para **drenar o
excesso das noturnas para os sábados**:
- Aula 1 e 2: intro enxuta, parada segura cedo; excedente vira demo/casa.
- Aula 2 → Aula 3: a comparação de "Data scanned" do Lab 04 é retomada/consolidada
  no sábado (Aula 3), que também compara CSV×Parquet.
- Aula 5 (EMR, quinta): lab com parada segura rígida + plano B; o que faltar é
  fechado no sábado (Aula 6).
- Cada aula tem uma **nota de gestão de tempo** específica; plano-de-aula atualizado.
`slidev build` passa.

### Refactor de tempo da PDN — Opção 1 ✅ (2026-10-29)
Diagnóstico: a Aula 3 (sábado, 5h) acumulava SageMaker (teoria+Lab C) + fechar
Lab A + Spark do Lab B — sobrecarregada; Aulas 1 e 2 (noturnas) com folga.
Refactor: **avançar labs nas noturnas** — Aula 1 **conclui o Lab A** (teoria de
EMR Serverless é curta); Aula 2 fecha a **ingestão** do Lab B. No sábado sobra
**uma** frente nova (SageMaker) + o Spark do Lab B; chegada = buffer; 20–25 min
reais de limpeza. Slides e plano-de-aula alinhados; `slidev build` passa.

### Revisão dos labs da GDBD (mesmo rigor da PDN) ✅ (2026-10-29)
Os 7 labs da GDBD passaram a usar **dados reais e atuais** (openfootball Premier
League 2024/25, JSON sem API key) em vez de CSVs inventados inline:
- Lab 01/02: CSV real gerado do JSON (`jogos`); schema evolution/crawler sobre
  dados reais.
- Lab 03: queries reescritas para a tabela `jogos` (gols em casa, goleada, rodada).
- Lab 04: particionamento **por `year`/`month`** derivado da data real dos jogos.
- Lab 05/06/07: CSV cru real alimenta os jobs Spark / camadas do Data Lake.
- READMEs ganharam seção "Dados do lab"; dry-runs checam **python3 + fonte
  acessível**. Geradores testados contra a fonte viva (380 jogos; partições
  2024-08…2025-05). Slides de Aula 1 e 2 alinhados ao dataset real. `build` passa.

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
10. [x] Rodar os `dry-run.sh` com credencial AWS real e executar os labs ponta a
    ponta (2026-11-08, autorizado pelo instrutor). Ver seção abaixo.

### Teste ponta a ponta na AWS real ✅ (2026-11-08)
Conta do instrutor (SSO AdministratorAccess, `us-east-1`). Cada lab foi rodado
copiando os comandos do `passo-a-passo.md`, conferindo o resultado e limpando.
Varredura final: **nenhum recurso de lab ligado** (custo estimado US$ 1–2,
quase todo de EMR).

| Lab | Resultado |
|---|---|
| GDBD 01 Glue Catalog | ✅ |
| GDBD 02 Glue Crawler | ⛔ conta bloqueada no Glue (ver abaixo; ✅ depois na conta principal) |
| GDBD 03 Athena | ✅ após correções |
| GDBD 04 Particionamento | ✅ via **Plano B** (Athena DDL + `MSCK REPAIR`): 1,4 KB vs 19,6 KB |
| GDBD 05 Glue Spark / 07 Data Lake | ⛔ não testados (mesmo bloqueio; ✅ depois na conta principal) |
| GDBD 06 EMR | ✅ transient (~5 min) + interativo com SSH e `spark-sql` |
| PDN A EMR Serverless | ✅ |
| PDN B Kinesis + Firehose + Spark | ✅ após correções |
| PDN C SageMaker | ✅ treino XGBoost, endpoint serverless, Batch Transform |

Bugs corrigidos:
- `$ACCOUNT_ID:role` vira modificador do zsh (`:r`) e quebrava o ARN em 9
  lugares de 6 labs → `${ACCOUNT_ID}:`.
- Lab 01 gerava só 4 colunas; o schema evolution "criava" `gols_visitante` sem
  dado e as queries do Lab 03 voltavam NULL. A query de `rodada` do Lab 03
  apontava para a tabela errada (só existe em `futebol_auto`).
- Lab 06: `KeyName` fictício derrubava o cluster (`VALIDATION_ERROR`). Novo
  passo 5b: cria a chave, libera SSH só para o IP do aluno, explora com
  `spark-sql`, limpa. Dry-run checa `ec2:CreateKeyPair` (`--dry-run`).
- PDN B: Firehose precisa de `sleep 15` após criar a role; o `stream_job.py`
  falhava (sink Parquet não aceita `complete`) → `foreachBatch`; glob para as
  subpastas do Firehose; `APP_ID` recuperado pelo nome.
- PDN C: dry-run checa quotas de ML; passo 5b com caminho CLI testado (o lab
  dependia de um notebook que não está no repo).
- Dry-runs 02/04/05/07: sonda `[conta]` que detecta o bloqueio do Glue sem
  criar nada.

**Bloqueio do Glue:** `CreateCrawler`/`CreateJob` → `Account <id> is denied
access`, em todas as regiões. Não é IAM nem SCP (a Organization só tem
`FullAWSAccess`; o CloudTrail registra a recusa antes da avaliação de IAM).
Restrição de conta da AWS: precisa de caso no **AWS Support → Account and
billing** (a API de Support exige plano pago; abrir pelo console).

**Quotas:** SageMaker vem com 0 para treino/transform em conta nova. Pedidos
abertos às 12:34; ~1 h depois a conta já tinha treino 20 / transform 8. vCPU
On-Demand do EC2 subiu de 8 para 256 no mesmo dia.

### Rodada limpa na conta principal ✅ (2026-11-08)
A conta `sandbox` (membro da Organization, criada em 2026-07) segue bloqueada no
Glue. A **conta principal** (management) tem o Glue liberado e virou a conta de
validação. Investigação: SCPs **não estão habilitadas** na raiz, não há RCP nem
políticas declarativas; a mesma sonda passa na principal e é barrada na sandbox
→ bloqueio da AWS na conta-membro, não permissão.

Os 10 labs rodaram de ponta a ponta executando **literalmente** os blocos `bash`
de cada `passo-a-passo.md` em zsh (o shell do aluno no Mac). Todos ✅, inclusive
02 (Crawler, refeito do zero para validar a ordem), 05 (Glue Job: 61 s, 122
DPU-s) e 07 (Raw → Glue Job → Crawler → CTAS). Correções desta rodada:
- **Propagação do IAM** (role recém-criada): `sleep` após criar a role no Lab 02
  (Crawler), Lab 06 (`create-default-roles` → "Invalid InstanceProfile") e Lab C
  (SageMaker → "Access Key Id does not exist").
- Labs 05 e 07: `--arguments "--INPUT=..."` era lido pela CLI como flag → JSON.
- Labs 05 e 07: a `GlueCrawlerLabRole` só lia o S3 → passo com política inline
  de escrita restrita aos buckets `gdbd-lab*`.
- Lab 05 passo 6: datas no formato errado (`dd/mm/aaaa`) e tabela indefinida →
  DDL concreto CSV × Parquet (medido: 846 B × 19 KB para a mesma resposta).
- Lab 07: esperar o job antes do Crawler (senão `clean/` está vazia).
- Lab 03: resultado esperado da query de `rodada` explicado (só 20 jogos têm).
- Lab 04 passo 6: lia o scan antes da query terminar (`null`).
- Lab 06: aviso sobre os `WARN` do `spark-sql`.
- Lab B: `pip install` no Python do sistema falha no 3.12+ (PEP 668) → venv.
- Lab C: bucket `pdn-lab02` → `pdn-lab03`; passo 5b dividido com as esperas.
- PDN: títulos padronizados como **Lab A/B/C** (iguais aos slides e ao site).
- Dry-runs 02/04/05/07: a sonda do Glue fica atrás de `--check-account`
  (regra de `labs.md`: nada de `create` sem flag explícita).

Varredura final na principal: só os recursos que já existiam (`carros`,
`concat_parquet`, 2 jobs, 16 buckets, notebook `Test` parado) + as roles
padrão do EMR (sem custo).

**Pendências:**
- [ ] (Opcional) Caso no AWS Support para liberar o Glue na conta `sandbox`.
- [x] Estratégia de contas AWS dos alunos decidida (issue #1, fechada):
  labs na **conta principal**; para o SageMaker, acesso temporário da turma
  via `tools/turma/turma.sh` (ver abaixo).

### Acesso da turma ao SageMaker ✅ (2026-11-08)
`tools/turma/turma.sh criar|status|limpar` cria usuários IAM temporários
(`<turma>-aNN`) que só usam CloudShell + SageMaker: treino/batch em
`ml.m5.large` até 15 min, endpoint só serverless, só recursos com o próprio
prefixo, pasta própria num bucket da turma. A política expira sozinha em
`--expira`. Guia do instrutor: `tools/turma/README.md`. Lab C ganhou a seção
"Modo turma". Testado: aluno pela CLI (lab completo), aluno no navegador (login
+ CloudShell + treino), 15 abusos negados, expiração (simulador IAM), `limpar`.
Quota atual da conta: 20 treinos e 8 batch simultâneos (o `criar` avisa).

### Trabalho final definido ✅ (2026-11-08)
O componente "Trabalho" estava só no CSV, sem enunciado. Agora existe (vale **100% da nota**, ver abaixo):
- Individual ou grupo de até 3 (aluno escolhe), **conta AWS do aluno**, prazo de
  **15 dias corridos** após a última aula. **SageMaker opcional** (+1,0).
- Cada grupo recebe um clube da Premier League pela matrícula do 1º integrante
  (`mod 20`); respostas por clube permitem correção por script.
- `tools/trabalho/trabalho.py` (**público**): `clube` e `validar` (aluno, só
  formato). O **corretor com o gabarito é privado**: repo
  privado `obernardocosta/big-data-privado` (clonar lado a lado com este). Faz 6,0 automáticos + 4,0 manuais (via
  `--manual` ou `correcao.json`) e `--csv`. Testado com entregas fictícias.
- GDBD: "Data Lake do meu clube" (Raw→Clean→Curated, 8 perguntas no Athena,
  comparação CSV × Parquet em bytes). PDN: "Pipeline e custo do meu clube"
  (EMR Serverless + Kinesis/Firehose + ADR com Pricing Calculator).
- Enunciados em `disciplinas/*/avaliacao/trabalho.md`, modelos em `trabalho-modelo/`,
  slides de apresentação (Aula 1) e entrega (última aula), agendas e steering
  atualizados.
- Pendências: [ ] rodar uma entrega real ponta a ponta na AWS (o enunciado ainda
  não foi executado por um aluno); [x] prazo: 15 dias corridos após a última aula; o trabalho é o último bloco
  de cada deck (`trabalho-final.md`) com link no sumário do site.

### Repositório privado das disciplinas ✅ (2026-11-08)
Criado `obernardocosta/big-data-privado` (PRIVATE) e movidos para lá: cálculo de
notas, planilhas das turmas e o corretor do trabalho. O público perdeu
`tools/notas/` e `avaliacao/notas/`; o `npm run notas` agora roda lá. Layout:
`notas/`, `correcao/`, `turmas/<disciplina>/<semestre>/{notas.csv,entregas/}`.
`tools/turma/` (acesso temporário dos alunos ao SageMaker) continua público: não
guarda dado de aluno (as credenciais vão para `~` e são ignoradas pelo Git).

### Nota = 100% trabalho ✅ (2026-11-08)
Presença e participação saíram do cálculo; a nota final é a nota do trabalho
(aprovação >= 6,0); labs não valem nota. Varredura feita em: enunciados e
READMEs de avaliação (GDBD/PDN), agendas, slides da Aula 1 de cada deck (slide
"Avaliação" e slide do trabalho), README da raiz, steering e neste checkpoint. No
repo privado: `calcular-notas.mjs` (CSV agora `matricula,nome,trabalho`; colunas
extras ignoradas), CSVs de exemplo e README.

### Planilha de turma com presença ✅ (2026-11-08)
No repo privado: `turmas/<disc>/<semestre>/turma.csv` (uma linha por aluno, uma
coluna por aula com P/F/-, mais `trabalho`), `npm run nova-turma` para criar e
`npm run notas` para o fechamento (faltas, frequência, nota e um bloco
matrícula | nome | nota | faltas para digitar na plataforma da faculdade). Linha
`#peso` opcional converte aula em quantidade de faltas (horas-aula). Regras no
topo do script: nota >= 6,0 e frequência >= 75% (a confirmar no regimento).


### Histórico reescrito ⚠️ (2026-11-08, autorizado pelo instrutor)
Os commits do fim do dia foram reescritos (force push) para tirar do repo
público uma versão antiga do corretor. O conteúdo atual não mudou. **Toda
sessão ou clone feito antes disso** precisa se realinhar antes de commitar:
`git fetch && git reset --hard origin/main` (salve antes qualquer mudança local
não enviada). Exceção única à regra "nunca force push".

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

# calcular notas: no repo privado (~/big-data-privado)
# npm run notas
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
  Em 2026-11-08 todos os dry-runs e 7 dos 10 labs foram rodados contra a conta
  AWS real (ver "Teste ponta a ponta na AWS real").
- Versionado em `obernardocosta/big-data` e publicado no Pages. Recursos AWS
  criados nos testes foram todos removidos; nenhuma credencial fica no repo.
