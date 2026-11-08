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

## Como este lab funciona

1. O instrutor faz uma **demo ao vivo** no console.
2. Você repete no **console**, seguindo o [passo a passo](passo-a-passo.md).
3. Cada passo tem o **script AWS CLI** recolhido, para travas ou para ganhar tempo.
   A preparação (gerar o CSV, escrever o PySpark e a política IAM) usa o script
   como caminho principal.
4. Encontrou algo errado? [Abra uma issue](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+07%5D+&labels=lab).

## Dados do lab

Dados **reais e atuais** da Premier League 2024/25 ([openfootball](https://github.com/openfootball/football.json), cópia no [repo data](https://github.com/obernardocosta/data/tree/main/football))
alimentam a camada **Raw**; as camadas Clean e Specialized são derivadas delas no
próprio lab.

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

**65 minutos**: ~5 min de demo ao vivo do instrutor + ~60 min de prática no console.
Os scripts AWS CLI (recolhidos em cada passo) servem para acelerar se o tempo apertar.

## Resultado esperado

Três camadas no S3 (`raw/`, `clean/`, `specialized/`), cada uma catalogada no
Glue e consultável no Athena, com a camada final pronta para consumo.

## Ponto de parada seguro

Se o tempo acabar, pare com as camadas **Raw** e **Clean** prontas e catalogadas
(passos 1–4). A camada **Specialized** (passo 5) vira demonstração ou exercício.

## Limpeza

Para não deixar nada para trás, apague na ordem abaixo.

**No console:**

1. [AWS Glue](https://console.aws.amazon.com/glue/) > **ETL jobs** (ou **Jobs**):
   selecione `lab07-raw-to-clean` e, em **Actions**, clique em **Delete job(s)**.
2. **Crawlers**: selecione `crawler-datalake` e clique em **Delete**.
3. **Data Catalog > Databases**: selecione `datalake_premier` e clique em **Delete**
   (as tabelas `premier` e `gols_por_time` somem junto).
4. [Amazon S3](https://console.aws.amazon.com/s3/): abra o seu bucket, **Empty** e
   depois **Delete** (isso apaga as camadas `raw/`, `clean/` e `specialized/`).

<details>
<summary>⚡ Prefere o terminal (AWS CLI)? Clique para ver o script</summary>

```bash
aws glue delete-job     --job-name lab07-raw-to-clean 2>/dev/null
aws glue delete-crawler --name crawler-datalake 2>/dev/null
aws glue delete-database --name datalake_premier 2>/dev/null
aws s3 rm s3://SEU-BUCKET/ --recursive
```

</details>

## O que isso prova

Que todas as peças do curso compõem **uma arquitetura coerente**: o Data Lake não
é um serviço novo, é a forma de **combinar** S3, Glue, Crawler/Catalog e Athena
em camadas. É o fechamento natural do caminho "open source → AWS".
