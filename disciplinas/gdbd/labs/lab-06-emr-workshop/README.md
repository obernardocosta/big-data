# Lab 06 — Amazon EMR workshop

## Por que estamos fazendo isso

Nos slides vimos o EMR como o **cluster Hadoop/Spark gerenciado** da AWS. Aqui
você sobe um cluster, roda um ETL em Spark e (extra) orquestra os passos com
**Step Functions**. É onde computação e armazenamento se **desacoplam** na
prática: o cluster processa, os dados ficam no S3.

> **Este é o lab mais sensível do curso.** Em turma anterior ele falhou por
> **indisponibilidade de instâncias** na região. O instrutor valida o ambiente
> na véspera e tem um plano B pronto (ver [troubleshooting](troubleshooting.md)).
> Se o seu cluster não subir, avise na hora e não insista sozinho.

## O que você aprende aqui

- Diferença entre cluster **transient** e **long running** e quando usar cada um.
- Papéis de **Master / Core / Task Node** e por que Task Node combina com Spot.
- **EMRFS**: por que manter os dados no S3 e o cluster efêmero.
- Boas práticas de particionamento, formato e escala vistas em aula.

## Como este lab funciona

1. O instrutor faz uma **demo ao vivo** no console.
2. Você repete no **console**, seguindo o [passo a passo](passo-a-passo.md).
3. Cada passo tem o **script AWS CLI** recolhido, para travas ou para ganhar tempo.
   A preparação (gerar o CSV e o `etl.py`) e a conexão **SSH** usam o script
   como caminho principal.
4. Encontrou algo errado? [Abra uma issue](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+06%5D+&labels=lab).

## Dados do lab

Dados **reais e atuais** da Premier League 2024/25 ([openfootball](https://github.com/openfootball/football.json), cópia no [repo data](https://github.com/obernardocosta/data/tree/main/football)).
O passo a passo gera o CSV cru a partir do JSON; o cluster EMR roda o ETL Spark
sobre ele.

## Pré-requisitos

| Item | Valor |
|---|---|
| Conta AWS | com acesso ao Console e à AWS CLI |
| Tipo de usuário | **IAM obrigatório** — root **não** conecta no EMR Notebooks |
| Região | `us-east-1` (tenha uma região alternativa pronta — ver plano B) |
| Serviços | Amazon EMR, Amazon S3, Amazon EC2, IAM (e Step Functions no extra) |
| Pré-requisito | roles de serviço do EMR (`EMR_DefaultRole`, `EMR_EC2_DefaultRole`) |
| Ferramentas | AWS CLI v2 configurada; cliente `ssh` (o par de chaves é criado no passo 5b) |

## Custo estimado

> **Custo aproximado: US$ 1.** O EMR cobra pelas **instâncias EC2 enquanto o
> cluster está de pé** (+ um fee do EMR). Um cluster pequeno e transient por
> ~30–60 min fica em torno de **US$ 1**. **Não deixe o cluster ligado.**

## Tempo estimado

**65 minutos**: ~5 min de demo ao vivo do instrutor + ~60 min de prática no console.
Os scripts AWS CLI (recolhidos em cada passo) servem para acelerar se o tempo apertar.

## Resultado esperado

Um cluster EMR transient que executa um ETL em Spark e grava Parquet no S3; e um
cluster long running em que você entra por SSH e consulta esse Parquet com
`spark-sql`/`pyspark` (e, no extra, uma Step Function orquestrando os steps).

## Ponto de parada seguro

Se o tempo acabar (ou instâncias não subirem), pare após o cluster ficar
`WAITING`/`RUNNING` e um step simples concluir. O **extra de Step Functions** é
opcional. Se o cluster não subir, **vá direto ao plano B** (demonstração) — não
queime tempo de aula tentando provisionar.

## Limpeza

**Encerre os clusters primeiro: é o que gera custo.**

**No console:**

1. [Amazon EMR](https://console.aws.amazon.com/emr/) > **Clusters**: selecione
   `lab06-emr-transient` e `lab06-emr-interativo` (se ainda estiverem ativos) e
   clique em **Terminate**. Confirme que o status final é **Terminated** e que não
   há nenhum cluster ativo (filtro **Active**).
2. [EC2 > Security Groups](https://console.aws.amazon.com/ec2/home#SecurityGroups):
   no security group do master, **Edit inbound rules** e apague a regra SSH
   (porta 22) do seu IP.
3. [EC2 > Key Pairs](https://console.aws.amazon.com/ec2/home#KeyPairs): apague a
   chave `lab06-...` e remova o `.pem` local.
4. [Amazon S3](https://console.aws.amazon.com/s3/): abra o seu bucket, **Empty** e
   depois **Delete**.
5. Se fez o extra: [AWS Step Functions](https://console.aws.amazon.com/states/),
   apague a máquina de estados que criou.

<details>
<summary>⚡ Prefere o terminal (AWS CLI)? Clique para ver o script</summary>

```bash
# ENCERRE O CLUSTER (é o que gera custo)
aws emr terminate-clusters --cluster-ids <CLUSTER_ID>

# confirme que terminou
aws emr describe-cluster --cluster-id <CLUSTER_ID> \
  --query 'Cluster.Status.State'

# cluster interativo do passo 5b + acesso SSH
aws emr terminate-clusters --cluster-ids <CLUSTER_ID2>
aws ec2 revoke-security-group-ingress --group-id <MASTER_SG> \
  --protocol tcp --port 22 --cidr <SEU_IP>/32
aws ec2 delete-key-pair --key-name <KEYNAME> && rm -f <KEYNAME>.pem

# confira que nada ficou ligado
aws emr list-clusters --active --query 'Clusters[].Id'

aws s3 rb s3://SEU-BUCKET/ --force
# remova a Step Function do extra, se criou
```

</details>

## O que isso prova

Que dá para rodar Hadoop/Spark de forma gerenciada e **econômica** desacoplando
cluster (efêmero) de armazenamento (S3 durável). É a base de processamento
pesada que alimenta o Data Lake da última aula.
