# Lab 01 — AWS Glue Data Catalog

## Por que estamos fazendo isso

Nos slides vimos que análises em SQL querem **tabelas**, não arquivos soltos. O
Glue Data Catalog é o equivalente gerenciado do Hive Metastore: é ele que dá a
visão estável de tabelas sobre arquivos no S3, registra o esquema e versiona
suas mudanças. Neste lab você cria, à mão, uma tabela catalogada e observa o
**schema evolution** acontecendo quando o esquema muda.

## O que você aprende aqui

- O que é um banco de dados e uma tabela no Glue Data Catalog.
- Como o catálogo separa a **definição da tabela** dos **arquivos** no S3.
- Como o catálogo **versiona** o esquema quando ele muda (Schema Evolution).
- Por que a catalogação manual não escala (gancho para o Lab 02, o Crawler).

## Dados do lab

Dados **reais e atuais** da Premier League 2024/25 do projeto público
**openfootball** (domínio público, sem API key):

```
https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json
```

O passo a passo gera um **CSV** a partir desse JSON (jogos reais) — nada de dados
inventados.

## Pré-requisitos

| Item | Valor |
|---|---|
| Conta AWS | com acesso ao Console e à AWS CLI |
| Tipo de usuário | **IAM** (não use o usuário root) |
| Região | `us-east-1` (ajuste se sua turma usar outra) |
| Serviços | Amazon S3, AWS Glue Data Catalog |
| Ferramentas | AWS CLI v2 configurada (`aws configure`) |

## Custo estimado

**Praticamente zero.** O Glue Data Catalog cobra por objetos armazenados acima
do primeiro milhão e por requisições acima do primeiro milhão/mês — este lab
fica muito abaixo disso. O S3 guarda poucos KB. Mesmo assim, faça a **Limpeza**
ao final.

## Tempo estimado

**15 minutos.**

## Resultado esperado

Uma tabela catalogada no Glue Data Catalog, com ao menos **duas versões de
esquema** registradas (antes e depois de adicionar uma coluna).

## Ponto de parada seguro

Se o tempo acabar, pare logo após criar a tabela e visualizá-la no console
(passo 4 do passo a passo). A parte de schema evolution (passo 5) pode ficar
como demonstração do instrutor.

## Limpeza

Para não deixar nada para trás:

```bash
aws glue delete-table    --database-name futebol --name jogos
aws glue delete-database --name futebol
aws s3 rm s3://SEU-BUCKET/jogos/ --recursive
```

## O que isso prova

Que o catálogo é uma camada de **metadados** independente dos arquivos: os dados
continuam como objetos no S3, mas as ferramentas de análise passam a enxergar
uma **tabela** estável e versionada. É exatamente o papel que o Hive Metastore
cumpre no mundo open source.
