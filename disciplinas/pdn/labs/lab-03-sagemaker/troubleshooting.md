# Lab 02 (PDN) — Troubleshooting

Erros comuns e como resolver. Rode o `dry-run.sh` primeiro — ele valida o
ambiente sem treinar nem criar endpoint (o que gera custo).

## ⚠️ O maior risco: Endpoint esquecido ligado

- O **Endpoint em tempo real cobra por hora enquanto existir**, mesmo sem
  requisições. É o item que mais gera cobrança surpresa no curso.
- Ao terminar (ou no fim da aula): `aws sagemaker delete-endpoint ...`. Confirme
  que não há nada ativo: `aws sagemaker list-endpoints`.

## "is not authorized to perform: iam:PassRole"

- Para criar Training Job/Endpoint com a **execution role**, seu usuário precisa
  de `iam:PassRole` sobre essa role.

## O Training Job falha com "AccessDenied" no S3

- Quem acessa o S3 é a **execution role**, não o seu usuário. Garanta leitura em
  `input/` e **escrita** em `model/`. No lab usamos `AmazonS3FullAccess`.

## "ResourceLimitExceeded" ao treinar ou criar endpoint

- A conta pode não ter quota para o tipo de instância de ML (ex.:
  `ml.m5.xlarge`). Peça aumento em **Service Quotas** (SageMaker) com
  antecedência, ou use um tipo menor disponível.

## O notebook não abre / kernel não conecta

- **Você está como root?** Use um usuário **IAM** (vale a mesma regra do EMR
  Notebooks da GDBD). Verifique também a execution role associada ao notebook.

## Batch Transform vs Endpoint — qual usar

- Se **não** precisa de resposta em tempo real, prefira **Batch Transform**: não
  deixa infraestrutura ligada e costuma ser bem mais barato para o lab.

## O deploy demora

- Criar um Endpoint provisiona instância e baixa o modelo — leva alguns minutos.
  Acompanhe `EndpointStatus` (`Creating` → `InService`).

## Plano B — sem orçamento para treinar/servir

1. Rode o `dry-run.sh` e, se faltar quota/orçamento, **não** crie o Endpoint.
2. Conduza como **demonstração**: mostre o notebook, um Training Job já
   concluído e a predição via **Batch Transform** (sem endpoint permanente), ou
   use os exemplos oficiais (`amazon-sagemaker-examples`). O objetivo (ciclo
   dados → treino → deploy) é aprendido sem manter endpoint no ar.
