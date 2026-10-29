# Lab 01 (PDN) — EMR Serverless (PySpark)

## Por que estamos fazendo isso

Na Aula 1 vimos que o **EMR Serverless** roda Spark **sem** você gerenciar
cluster: a abstração vira recurso (vCPU/RAM) e cada job tem sua **RuntimeRole**.
Neste lab você cria uma **Application**, submete um **job PySpark** com suas
**dependências Python** e observa o modelo serverless na prática — o passo
natural depois do EMR tradicional da GDBD.

## O que você aprende aqui

- Criar uma **Application** EMR Serverless (tipo Spark).
- Submeter um **job run** com uma **RuntimeRole** por job (menor privilégio).
- Empacotar e enviar **dependências Python** para o job.
- (Extra) Rodar uma **Hive query** no EMR Serverless.

## Pré-requisitos

| Item | Valor |
|---|---|
| Conta AWS | com acesso ao Console e à AWS CLI |
| Tipo de usuário | **IAM** (não use o usuário root) |
| Região | `us-east-1` (ajuste se sua turma usar outra) |
| Serviços | Amazon EMR Serverless, Amazon S3, IAM |
| Pré-requisito | uma **RuntimeRole** (job role) com acesso ao S3 do lab |
| Ferramentas | AWS CLI v2 configurada |
| Base oficial | https://github.com/aws-samples/emr-serverless-samples |

## Custo estimado

> **Centavos a ~US$ 0,50.** O EMR Serverless cobra por **vCPU-hora** e
> **GB-hora** enquanto o job roda — jobs pequenos deste lab custam frações de
> dólar e **não há cluster ocioso** cobrando. Ainda assim, faça a **Limpeza**.

## Tempo estimado

**2h30** (é o lab principal da aula de sábado; inclui pré-requisitos).

## Resultado esperado

Um job PySpark concluído (`SUCCESS`) numa Application EMR Serverless, com a saída
gravada no S3 e as dependências Python resolvidas.

## Ponto de parada seguro

Se o tempo acabar, pare com o **PySpark job obrigatório** concluído. O lab de
**Python Dependencies** e o **extra de Hive** podem virar demonstração.

## Limpeza

```bash
# pare/cancele jobs e remova a Application (nao fica recurso ocioso, mas limpe)
aws emr-serverless list-applications \
  --query 'applications[?name==`lab-pdn-emrs`].id' --output text
aws emr-serverless delete-application --application-id <APP_ID>
aws s3 rm s3://SEU-BUCKET/ --recursive
# remova a RuntimeRole do lab se nao for reutilizar
```

## O que isso prova

Que dá para rodar Spark em escala **sem operar cluster**: a Application sobe
capacidade sob demanda e a solta depois, e a **RuntimeRole por job** aplica menor
privilégio de verdade. É o EMR da GDBD, sem o peso operacional.
