# Lab 01 — Troubleshooting

Erros comuns e como resolver. Rode o `dry-run.sh` primeiro: ele aponta a maioria
destes problemas antes da aula.

## "Unable to locate credentials" / credencial inválida

- Rode `aws configure` e informe Access Key, Secret e região.
- Confirme com `aws sts get-caller-identity`.

## Estou como usuário root

- O catálogo funciona como root, mas é **má prática** e alguns passos do curso
  (ex.: EMR Notebooks em labs futuros) **não** funcionam com root.
- Crie/entre com um usuário IAM com as políticas de Glue e S3.

## "AccessDenied" ao chamar Glue ou S3

- Falta permissão. Para o lab, o usuário precisa de algo equivalente a
  `AWSGlueConsoleFullAccess` + `AmazonS3FullAccess` (ou políticas mais restritas
  com as ações `glue:*Table*`, `glue:*Database*`, `s3:*` no bucket do lab).

## "BucketAlreadyExists" ao criar o bucket

- Nomes de bucket S3 são **globais**. Escolha outro nome (o passo a passo já usa
  um sufixo aleatório para evitar isso).

## A região "não tem" meu recurso

- Você criou o recurso numa região e está consultando em outra. Padronize a
  região: `export AWS_REGION=us-east-1` e use a mesma em todos os comandos.

## Plano B — serviço indisponível na região

Se o Glue estiver instável ou indisponível na região da turma (já aconteceu com
outros serviços, como a indisponibilidade de instâncias GPU numa turma de PDN):

1. Troque a região (`us-east-1`, `us-east-2`, `sa-east-1`) e rode o `dry-run.sh`
   de novo para confirmar.
2. Se persistir, conduza este lab como **demonstração** a partir da saída já
   gerada e siga para o conteúdo. Não gaste tempo de aula tentando subir o
   ambiente — essa é uma lição da preparação prévia.
