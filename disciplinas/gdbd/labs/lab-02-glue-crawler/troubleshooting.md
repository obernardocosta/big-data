# Lab 02 — Troubleshooting

Erros comuns e como resolver. Rode o `dry-run.sh` deste lab primeiro: ele aponta
a maioria destes problemas antes da aula.

## "Unable to locate credentials" / credencial inválida

- Rode `aws configure` e informe Access Key, Secret e região.
- Confirme com `aws sts get-caller-identity`.

## Estou como usuário root

- O Crawler pode até rodar como root, mas é **má prática**. Use um usuário IAM
  com permissões de Glue, S3 e IAM (este lab cria uma role de serviço).

## "AccessDenied" ao chamar Glue, S3 ou IAM

- Falta permissão. Para o lab, o usuário precisa de algo equivalente a
  `AWSGlueConsoleFullAccess` + `AmazonS3FullAccess` e permissão de IAM para
  **criar e vincular uma role** (`iam:CreateRole`, `iam:AttachRolePolicy`,
  `iam:PassRole`). Sem `iam:PassRole`, o passo 4 (criar o Crawler) falha mesmo
  com a role já existindo.

## "The specified role ... cannot be assumed by Glue"

- A *trust policy* da role precisa permitir o principal `glue.amazonaws.com`.
  Confira o `trust.json` do passo 2 — o `Principal.Service` deve ser exatamente
  `glue.amazonaws.com`.
- Recém-criada, a role pode levar alguns segundos para propagar. Espere e tente
  rodar o Crawler de novo.

## O Crawler roda mas NÃO cria tabela

- Causa mais comum: o alvo aponta para o **arquivo** em vez da **pasta**. Use o
  prefixo `s3://SEU-BUCKET/jogadores/` (com a barra final), não o `.csv`.
- Confirme que há objetos no caminho: `aws s3 ls s3://SEU-BUCKET/jogadores/`.
- A role precisa de leitura no bucket (`AmazonS3ReadOnlyAccess` ou equivalente).

## O Crawler fica "RUNNING" e não termina

- Rodadas sobre poucos arquivos levam segundos a ~1-2 min. Acompanhe o estado
  com `aws glue get-crawler --name crawler-jogadores --query 'Crawler.State'`
  (RUNNING → STOPPING → READY). Se travar, pare com
  `aws glue stop-crawler --name crawler-jogadores` e verifique permissões da role.

## A coluna nova não apareceu na segunda rodada

- Confirme que o novo arquivo foi para a **mesma pasta** (`jogadores/`) e que o
  Crawler rodou de novo até `READY`. O Crawler só reflete o que está no S3 no
  momento da varredura.

## "BucketAlreadyExists" ao criar o bucket

- Nomes de bucket S3 são **globais**. O passo a passo já usa um sufixo aleatório
  (`$RANDOM`); se ainda colidir, rode de novo para gerar outro nome.

## A região "não tem" meu recurso

- Você criou o recurso numa região e está consultando em outra. Padronize:
  `export AWS_REGION=us-east-1` e use a mesma região em todos os comandos.

## Plano B — serviço indisponível na região

Se o Glue estiver instável ou indisponível na região da turma (já aconteceu com
outros serviços, como a indisponibilidade de instâncias GPU numa turma de PDN):

1. Troque a região (`us-east-1`, `us-east-2`, `sa-east-1`) e rode o `dry-run.sh`
   de novo para confirmar.
2. Se persistir, conduza o lab como **demonstração** a partir de uma saída já
   gerada e siga para o conteúdo. Não gaste tempo de aula tentando subir o
   ambiente — essa é justamente a lição da preparação prévia com o `dry-run.sh`.
