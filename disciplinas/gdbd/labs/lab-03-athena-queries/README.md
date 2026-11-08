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

## Como este lab funciona

1. O instrutor faz uma **demo ao vivo** no console.
2. Você repete no **console**, seguindo o [passo a passo](passo-a-passo.md).
3. Cada passo tem o **script AWS CLI** recolhido, para travas ou para ganhar tempo.
4. Encontrou algo errado? [Abra uma issue](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+03%5D+&labels=lab).

## Dados do lab

Consulta a tabela `jogos` catalogada nos Labs 01/02 — dados **reais** da Premier
League 2024/25 ([openfootball](https://github.com/openfootball/football.json), cópia no [repo data](https://github.com/obernardocosta/data/tree/main/football)). Sem dados inventados.

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

**50 minutos**: ~5 min de demo ao vivo do instrutor + ~45 min de prática no console.
Os scripts AWS CLI (recolhidos em cada passo) servem para acelerar se o tempo apertar.

## Resultado esperado

Executar consultas SQL no Athena sobre a tabela catalogada e obter as respostas
de negócio (times que mais marcam, maior goleada, gols por rodada), observando o
**volume de dados escaneado** em cada consulta.

## Ponto de parada seguro

Se o tempo acabar, pare assim que a **primeira consulta** rodar com sucesso e
retornar linhas (passo 4). As demais perguntas viram demonstração ou exercício.

## Limpeza

O Athena em si não deixa recurso ligado: limpe só os resultados no S3.

**No console:**

1. [Amazon S3](https://console.aws.amazon.com/s3/): abra o bucket de results
   (`gdbd-lab03-results-...`), clique em **Empty** e confirme; depois **Delete**
   o bucket.
2. Se criou um *workgroup* dedicado para o lab: [Amazon
   Athena](https://console.aws.amazon.com/athena/) > **Workgroups**, selecione-o
   e clique em **Delete** (marcando a opção de apagar também os query results).
3. As tabelas e databases do Glue pertencem aos Labs 01/02: apague-os pela
   Limpeza desses labs.

<details>
<summary>⚡ Prefere o terminal (AWS CLI)? Clique para ver o script</summary>

```bash
# o Athena em si não deixa recurso ligado; limpe só os resultados no S3
aws s3 rm s3://SEU-BUCKET-RESULTS/ --recursive
# se criou um workgroup dedicado para o lab:
# aws athena delete-work-group --work-group lab03 --recursive-delete-option
```

</details>

## O que isso prova

Que catálogo (Aula 1) e motor de consulta (Athena) se encaixam: a mesma tabela
catalogada passa a responder SQL distribuído **sem servidor nenhum**. E que cada
consulta tem um custo mensurável — o que motiva o particionamento do Lab 04.
