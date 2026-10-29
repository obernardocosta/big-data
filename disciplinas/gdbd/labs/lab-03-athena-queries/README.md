# Lab 03 — Consultas no Amazon Athena

## Por que estamos fazendo isso

Nos Labs 01 e 02 criamos tabelas no Glue Data Catalog. Mas catálogo sem consulta
não responde pergunta de negócio nenhuma. Nos slides vimos que o **Amazon
Athena** é o PrestoDB **serverless**: ele roda SQL distribuído direto sobre os
arquivos no S3, usando o catálogo que já temos. Neste lab você finalmente
**consulta** os dados catalogados e responde perguntas reais.

## O que você aprende aqui

- Como o Athena usa o **Glue Data Catalog** para saber onde estão os dados.
- Por que o Athena precisa de um **bucket de query results** além do bucket de dados.
- Como o modelo de cobrança (**US$ 5 por TB escaneado**) liga consulta a custo.
- A ler o campo **"Data scanned"** — gancho direto para o Lab 04 (particionamento).

## Pré-requisitos

| Item | Valor |
|---|---|
| Conta AWS | com acesso ao Console e à AWS CLI |
| Tipo de usuário | **IAM** (não use o usuário root) |
| Região | `us-east-1` (ajuste se sua turma usar outra) |
| Serviços | Amazon Athena, AWS Glue Data Catalog, Amazon S3 |
| Pré-requisito | uma tabela catalogada (saída do Lab 01 ou 02) |
| Ferramentas | AWS CLI v2 configurada |

## Custo estimado

**Centavos.** O Athena cobra US$ 5 por **TB escaneado**; os dados deste lab têm
poucos KB, então cada consulta custa frações de centavo. Ainda assim, faça a
**Limpeza** ao final.

## Tempo estimado

**45 minutos.**

## Resultado esperado

Executar consultas SQL no Athena sobre a tabela catalogada e obter as respostas
de negócio (top 10 jogadores, país com mais prêmios, etc.), observando o
**volume de dados escaneado** em cada consulta.

## Ponto de parada seguro

Se o tempo acabar, pare assim que a **primeira consulta** rodar com sucesso e
retornar linhas (passo 4). As demais perguntas viram demonstração ou exercício.

## Limpeza

```bash
# o Athena em si não deixa recurso ligado; limpe só os resultados no S3
aws s3 rm s3://SEU-BUCKET-RESULTS/ --recursive
# se criou um workgroup dedicado para o lab:
# aws athena delete-work-group --work-group lab03 --recursive-delete-option
```

## O que isso prova

Que catálogo (Aula 1) e motor de consulta (Athena) se encaixam: a mesma tabela
catalogada passa a responder SQL distribuído **sem servidor nenhum**. E que cada
consulta tem um custo mensurável — o que motiva o particionamento do Lab 04.
