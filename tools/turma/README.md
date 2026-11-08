# Acesso da turma ao SageMaker (conta do instrutor)

Script para dar aos alunos um acesso **temporário, isolado e barato** ao
SageMaker da sua conta, para o Lab C da PDN. Existe porque conta AWS nova vem
com quota **0** de treino no SageMaker, e o pedido de aumento leva dias.

Testado de ponta a ponta em 2026-11-08 na conta principal: login de aluno no
console, CloudShell, treino, endpoint serverless, predição, Batch Transform e
limpeza, além de 15 tentativas de abuso negadas (ver "O que foi testado").

## O que o aluno pode e não pode

| Pode | Não pode |
|---|---|
| CloudShell (terminal no navegador, grátis) | Notebook (cobra enquanto fica ligado) |
| Ler/gravar só na **própria** pasta do bucket da turma | Ver ou mexer na pasta ou nos recursos de colegas |
| Treino e Batch Transform em `ml.m5.large`, **até 15 min** por job | Qualquer outra instância (GPU, xlarge...) ou job sem limite de tempo |
| Endpoint **serverless** (≤ 2 GB, concorrência 1) | Endpoint provisionado (cobra por hora parado) |
| Recursos com nome começando pelo próprio usuário | IAM, EC2, Glue, S3 de outros buckets, outras roles |

Tudo **expira sozinho** às 23:59 UTC da data de `--expira`, mesmo que você
esqueça de rodar o `limpar`.

## Quanto custa

- Por aluno, o Lab C sai por **centavos**: o treino dura ~2 min em `ml.m5.large`
  (US$ 0,115/h), o endpoint serverless cobra por requisição e o Batch Transform
  leva ~5 min.
- Um endpoint esquecido **não cobra parado**: só existem endpoints serverless.
- No pior caso (aluno disparando jobs sem parar até a expiração), o limite é a
  quota da conta, 20 instâncias `ml.m5.large`, o que dá ~US$ 2,30/h. Por isso:
  use `--expira` curto e `--email` para receber o alerta de gasto.

## Passo a passo do instrutor

### 1. Na véspera (5 min)

Faça login no portal SSO e copie as credenciais de **administrador da conta
principal** para o terminal (o bloco `export AWS_ACCESS_KEY_ID=...`). Depois,
na raiz do repositório:

```bash
tools/turma/turma.sh criar \
  --turma pdn-2026-2 \
  --alunos 30 \
  --expira 2026-12-15 \
  --email voce@exemplo.com \
  --orcamento 20
```

- `--turma`: identificador curto, só `a-z 0-9 -`, até 20 caracteres. Vira
  prefixo de tudo (usuários `pdn-2026-2-a01`, `-a02`...).
- `--expira`: último dia de acesso. Use o dia da aula, ou o fim do curso se o
  lab for para casa.
- `--email` / `--orcamento`: alerta por e-mail ao passar de 50% e 100% do
  valor mensal em SageMaker. O alerta **avisa, não bloqueia**; as travas
  acima é que limitam o gasto.

O script mostra um **aviso** se a turma for maior que a quota de jobs
simultâneos. Hoje a conta tem 20 para treino e 8 para Batch Transform. Com 30
alunos, quem passar disso recebe `ResourceLimitExceeded` e tenta de novo em
~3 min. Para evitar, rode o comando de aumento que o aviso imprime, de
preferência uma semana antes (é grátis).

### 2. Distribuir os acessos

O script grava as senhas em `~/turma-<turma>-credenciais.csv`: só você lê o
arquivo, e ele fica **fora** do repositório. Entregue a cada aluno a linha dele
(usuário, senha e link de login) por um canal individual. O Classroom com
mensagem privada serve.

O script também imprime as instruções para colar no slide: link de login, link
do CloudShell e as duas variáveis (`TURMA_BUCKET` e `SM_ROLE`). O aluno segue
a seção **"Modo turma"** do `passo-a-passo.md` do Lab C.

### 3. Durante a aula

```bash
tools/turma/turma.sh status --turma pdn-2026-2
```

Mostra os endpoints ativos, os jobs rodando e quantos treinos cada aluno já
concluiu (bom para conferir a participação no lab).

Problemas comuns dos alunos:

- **`AccessDenied`**: o nome do recurso não começa com o usuário dele, a
  instância não é `ml.m5.large` ou o endpoint não é serverless. O passo a passo
  já usa os valores certos: peça para não mudar.
- **`ResourceLimitExceeded`**: quota da conta cheia (muitos treinando ao mesmo
  tempo). Esperar ~3 min e tentar de novo.
- **Console em us-east-2**: o login cai em Ohio. Usar o link do CloudShell, que
  já abre em us-east-1.

### 4. Depois da aula (ou no fim do curso)

```bash
tools/turma/turma.sh limpar --turma pdn-2026-2
```

Pede para digitar o nome da turma como confirmação (`--sim` pula a pergunta).
Apaga os endpoints, configs e modelos dos alunos, para os jobs em andamento,
remove os usuários, o grupo, a role, o bucket, o orçamento e o arquivo de
senhas. Os registros dos jobs concluídos ficam no histórico do SageMaker: é
assim mesmo, eles não custam nada.

## O que foi testado (2026-11-08)

Turma `kiro-teste` com 2 alunos, na conta principal:

- Aluno A, pela CLI (mesmas permissões do CloudShell): Lab C completo no modo
  turma, com treino, endpoint serverless, predição e Batch Transform de 80
  linhas.
- Aluno B, **no navegador**: login no console com a senha gerada, CloudShell
  aberto, upload para a própria pasta e treino concluído.
- 15 tentativas negadas como deveriam: `ml.m5.xlarge`, GPU, treino de 1 h,
  endpoint provisionado, serverless grande, notebook, batch em `m5.4xlarge`,
  nome sem prefixo, ler e gravar na pasta do colega, listar buckets, passar
  outra role, criar usuário IAM, ler o Glue do instrutor, subir EC2, e o aluno
  B apagar ou invocar o endpoint do aluno A.
- Expiração (simulador do IAM): permitido antes da data, negado depois,
  inclusive o CloudShell.
- `limpar`: removeu tudo, inclusive um endpoint deixado ligado de propósito.

## Segurança: o que ter em mente

- A conta principal é a **conta de gerenciamento da Organization**, e a AWS
  recomenda não ter workloads nem usuários de terceiros nela. Este script
  limita o risco (permissões mínimas, prazo, isolamento), mas não o elimina.
  Se um dia uma conta-membro tiver o Glue e o SageMaker liberados, prefira
  rodar a turma lá: o script funciona igual em qualquer conta.
- Usuários sem MFA, com senha entregue pelo instrutor: é o que torna o acesso
  rápido. O prazo curto (`--expira`) é o que compensa.
- Nunca commite o arquivo `~/turma-*-credenciais.csv`.
