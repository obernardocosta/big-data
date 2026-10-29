# Lab 06 — Troubleshooting

Este é o lab mais sensível do curso. Rode o `dry-run.sh` **reforçado** na
véspera — a maioria dos problemas abaixo é pega por ele.

## O cluster fica em "STARTING" e depois falha / instâncias não sobem

**Este foi o incidente de uma turma anterior.** Causas e saídas:

- **Capacidade insuficiente na região/AZ** (`Insufficient capacity`): a AWS não
  tem a instância naquele momento. Soluções:
  1. Troque o **tipo de instância** (ex.: `m5.xlarge` → `m4.xlarge` → `m5a.xlarge`).
  2. Troque a **região** (`us-east-1` → `us-east-2` → `sa-east-1`) e rode o
     `dry-run.sh` de novo.
  3. Não use Spot para o Master/Core neste lab (Spot some sob demanda); deixe
     Spot só para Task Node, se usar.
- **Quota de vCPU estourada**: peça aumento em Service Quotas (código
  `L-1216C47A`) com antecedência — não dá para resolver na hora da aula.

## "You must specify a key pair" / não consigo SSH

- O SSH é **opcional** neste lab. Para usar, informe um par de chaves existente
  (`--ec2-attributes KeyName=...`) e libere a **porta 22** no Security Group
  **só para o seu IP** (nunca `0.0.0.0/0`).

## Não consigo conectar no EMR Notebooks

- **Você está como root.** O EMR Notebooks **exige usuário IAM**. Entre com um
  usuário IAM com as permissões de EMR/EC2/S3.

## "EMR_DefaultRole is invalid" / roles ausentes

- Rode `aws emr create-default-roles` (não gera custo) antes de criar o cluster.
  Isso cria `EMR_DefaultRole` e `EMR_EC2_DefaultRole`.

## O step de Spark falhou (step FAILED)

- Veja os logs em `s3://SEU-BUCKET/logs/` (configurado via `--log-uri`) ou no
  console do EMR. Erros comuns: caminho de entrada/saída errado, colunas que não
  batem com o CSV, saída já existente (use `mode("overwrite")`).

## Tenho medo de esquecer o cluster ligado

- Use `--auto-terminate` (cluster transient): ele se encerra ao fim dos steps.
- Confira o estado: `aws emr list-clusters --active`. Se houver algo ativo:
  `aws emr terminate-clusters --cluster-ids <ID>`.
- **O custo vem das instâncias enquanto o cluster está de pé** — terminar o
  cluster estanca a cobrança.

## Plano B — não subiu a tempo (regra do feedback)

Se, mesmo com a preparação, o cluster não subir no horário da aula:

1. **Não queime tempo de aula** tentando provisionar.
2. Conduza como **demonstração**: mostre a criação no console, explique
   Master/Core/Task, transient vs long running e as boas práticas, usando uma
   saída já capturada e os logs de uma execução anterior.
3. O extra de **Step Functions** também pode ser demonstrado a partir de um
   diagrama/template pronto.

O objetivo pedagógico (desacoplar computação de storage, cluster efêmero) é
alcançado mesmo sem subir o cluster ao vivo. Essa é a lição da preparação prévia.
