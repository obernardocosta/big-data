# Lab 07 — Data Lake de 3 camadas (lab final)

## Por que estamos fazendo isso

Este é o lab que **amarra o curso inteiro**. Nos slides vimos que um Data Lake
organiza os dados em camadas (Raw → Clean → Specialized), cada uma refinando a
anterior. Aqui você monta essa arquitetura no S3 usando tudo que aprendeu:
catálogo, transformação, particionamento e consulta.

## O que você aprende aqui

- Como desenhar um Data Lake em **3 camadas** e por que a Raw nunca se perde.
- Como cada serviço do curso ocupa um lugar na arquitetura (S3, Glue, Crawler,
  Athena).
- Por que **schema on read** e o **desacoplamento storage/computação** tornam
  isso barato e flexível.

## Pré-requisitos

| Item | Valor |
|---|---|
| Conta AWS | com acesso ao Console e à AWS CLI |
| Tipo de usuário | **IAM** (não use o usuário root) |
| Região | `us-east-1` (ajuste se sua turma usar outra) |
| Serviços | Amazon S3, AWS Glue (Job + Crawler + Catalog), Amazon Athena, IAM |
| Pré-requisito | a role de serviço do Glue (dos labs 02/05, com leitura+escrita no S3) |
| Ferramentas | AWS CLI v2 configurada |

## Custo estimado

**Centavos a ~US$ 0,30.** O S3 guarda poucos dados; Crawler e Athena custam
frações de centavo; o único item com custo relevante é o(s) **Glue Job(s)** de
transformação entre camadas (DPU-hora, como no Lab 05). Faça a **Limpeza**.

## Tempo estimado

**60 minutos.**

## Resultado esperado

Três camadas no S3 (`raw/`, `clean/`, `specialized/`), cada uma catalogada no
Glue e consultável no Athena, com a camada final pronta para consumo.

## Ponto de parada seguro

Se o tempo acabar, pare com as camadas **Raw** e **Clean** prontas e catalogadas
(passos 1–4). A camada **Specialized** (passo 5) vira demonstração ou exercício.

## Limpeza

```bash
aws glue delete-job     --job-name lab07-raw-to-clean 2>/dev/null
aws glue delete-crawler --name crawler-datalake 2>/dev/null
aws glue delete-database --name datalake_premier 2>/dev/null
aws s3 rm s3://SEU-BUCKET/ --recursive
```

## O que isso prova

Que todas as peças do curso compõem **uma arquitetura coerente**: o Data Lake não
é um serviço novo, é a forma de **combinar** S3, Glue, Crawler/Catalog e Athena
em camadas. É o fechamento natural do caminho "open source → AWS".
