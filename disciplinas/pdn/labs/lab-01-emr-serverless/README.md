# PDN Lab 01 (Lab A) — EMR Serverless (PySpark)

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

## Como este lab funciona

1. O instrutor faz uma **demo ao vivo** no console.
2. Você repete no **console**, seguindo o [passo a passo](passo-a-passo.md).
3. Cada passo tem o **script AWS CLI** recolhido, para travas ou para ganhar tempo.
4. Encontrou algo errado? [Abra uma issue](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BPDN+Lab+01%5D+&labels=lab).

## Dados do lab

Usamos dados **públicos e atuais** da Premier League (temporada 2024/25) do
projeto open source **openfootball** (domínio público), copiado no repo **[data](https://github.com/obernardocosta/data)**:

```
https://raw.githubusercontent.com/obernardocosta/data/main/football/premier-league/2024-25/en.1.json
```

O job PySpark lê esse JSON de jogos reais e calcula agregados (ex.: gols por
time). O dado é baixado do nosso repo de dados (**data**), uma cópia exata da fonte aberta.

## Pré-requisitos

| Item | Valor |
|---|---|
| Conta AWS | com acesso ao Console e à AWS CLI |
| Tipo de usuário | **IAM** (não use o usuário root) |
| Região | `us-east-1` (ajuste se sua turma usar outra) |
| Serviços | Amazon EMR Serverless, Amazon S3, IAM |
| Pré-requisito | uma **RuntimeRole** (job role) com acesso ao S3 do lab |
| Ferramentas | AWS CLI v2 configurada |
| Base oficial | [aws-samples/emr-serverless-samples](https://github.com/aws-samples/emr-serverless-samples) |

## Custo estimado

> **Centavos a ~US$ 0,50.** O EMR Serverless cobra por **vCPU-hora** e
> **GB-hora** enquanto o job roda — jobs pequenos deste lab custam frações de
> dólar e **não há cluster ocioso** cobrando. Ainda assim, faça a **Limpeza**.

## Tempo estimado

**2h35**: ~5 min de demo ao vivo do instrutor + ~2h30 de prática no console (é o
lab principal da Aula 1; inclui pré-requisitos). Os scripts AWS CLI (recolhidos
em cada passo) servem para acelerar se o tempo apertar.

## Resultado esperado

Um job PySpark concluído (`SUCCESS`) numa Application EMR Serverless, com a saída
gravada no S3 e as dependências Python resolvidas.

## Ponto de parada seguro

Se o tempo acabar, pare com o **PySpark job obrigatório** concluído. O lab de
**Python Dependencies** e o **extra de Hive** podem virar demonstração.

## Limpeza

Não fica recurso ocioso cobrando, mas limpe mesmo assim. **Atenção:** a Application
é reaproveitada no Lab B (Spark Streaming); só apague depois de fechar o Lab B.

**No console:**

1. [Amazon EMR](https://console.aws.amazon.com/emr/) > **EMR Serverless**: abra a
   Application `lab-pdn-emrs`, cancele jobs em andamento (**Job runs**), clique em
   **Actions > Stop** e, depois de parada, **Actions > Delete**.
2. [Amazon S3](https://console.aws.amazon.com/s3/): selecione o seu bucket, clique
   em **Empty** e depois em **Delete**.
3. [IAM](https://console.aws.amazon.com/iam/) > **Roles**: apague a
   `EMRServerlessJobRole`, se não for reutilizar (ela também serve ao Lab B).

<details>
<summary>⚡ Prefere o terminal (AWS CLI)? Clique para ver o script</summary>

```bash
# pare/cancele jobs e remova a Application (nao fica recurso ocioso, mas limpe)
aws emr-serverless list-applications \
  --query 'applications[?name==`lab-pdn-emrs`].id' --output text
aws emr-serverless delete-application --application-id <APP_ID>
aws s3 rm s3://SEU-BUCKET/ --recursive
# remova a RuntimeRole do lab se nao for reutilizar
```

</details>

## O que isso prova

Que dá para rodar Spark em escala **sem operar cluster**: a Application sobe
capacidade sob demanda e a solta depois, e a **RuntimeRole por job** aplica menor
privilégio de verdade. É o EMR da GDBD, sem o peso operacional.
