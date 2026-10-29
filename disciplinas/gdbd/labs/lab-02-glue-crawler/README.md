# Lab 02 — AWS Glue Crawler

## Por que estamos fazendo isso

No Lab 01 criamos uma tabela **à mão**. Nas Considerações dos slides vimos que
isso não escala: dezenas de colunas, centenas de tabelas, dezenas de tabelas
novas por dia. O **Glue Crawler** resolve isso: ele varre os arquivos no S3,
**infere o esquema** e cria/atualiza as tabelas no catálogo automaticamente.

## O que você aprende aqui

- Como o Crawler infere esquema e **cria tabelas automaticamente**.
- Como ele **atualiza** o esquema quando novos arquivos chegam.
- O modelo de cobrança serverless (paga só pela varredura).
- Por que automação de catálogo é pré-requisito para um Data Lake saudável.

## Dados do lab

Dados **reais e atuais** da Premier League 2024/25 do projeto público
**openfootball** (domínio público, sem API key). O passo a passo gera o CSV a
partir do JSON — o Crawler infere o esquema desses jogos reais.

## Pré-requisitos

| Item | Valor |
|---|---|
| Conta AWS | com acesso ao Console e à AWS CLI |
| Tipo de usuário | **IAM** (não use o usuário root) |
| Região | `us-east-1` (ajuste se sua turma usar outra) |
| Serviços | Amazon S3, AWS Glue (Crawler + Data Catalog), IAM |
| Pré-requisito extra | uma **IAM Role** para o Glue assumir (o passo a passo mostra) |
| Ferramentas | AWS CLI v2 configurada |

## Custo estimado

**Centavos.** O Crawler cobra por tempo de execução (DPU-hora) e rodadas curtas
custam frações de centavo. Faça a **Limpeza** ao final mesmo assim.

## Tempo estimado

**30 minutos.**

## Resultado esperado

Uma tabela criada **automaticamente** pelo Glue Crawler, com o esquema inferido a
partir dos arquivos no S3.

## Ponto de parada seguro

Se o tempo acabar, pare assim que o Crawler rodar com sucesso e a tabela
aparecer no catálogo (passo 5). A segunda execução (atualização de esquema,
passo 6) pode virar demonstração.

## Limpeza

```bash
aws glue delete-crawler --name crawler-jogos
aws glue delete-table    --database-name futebol_auto --name <NOME_DA_TABELA_CRIADA>
aws glue delete-database --name futebol_auto
aws s3 rm s3://SEU-BUCKET/ --recursive
# remova a role do lab se não for reutilizá-la
```

## O que isso prova

Que a catalogação deixa de ser trabalho manual e vira **automação orientada a
dados**: quando novos arquivos chegam ao S3, o Crawler mantém o catálogo em dia.
É o que torna viável um Data Lake com muitas fontes.
