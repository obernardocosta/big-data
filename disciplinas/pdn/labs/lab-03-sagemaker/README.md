# PDN Lab 03 (Lab C) — Amazon SageMaker (treino + deploy)

## Por que estamos fazendo isso

Na Aula 2 vimos que o **SageMaker** transforma cada dor de infra de ML
(servidor, GPU, API, monitoração) em um recurso gerenciado (Notebook, Training
Job, Model Registry, Endpoint). Neste lab você percorre o ciclo de ponta a
ponta: **manipular os dados → treinar o modelo → fazer o deploy**.

## O que você aprende aqui

- Usar um **Notebook** gerenciado do SageMaker para preparar dados.
- Rodar um **Training Job** (infra sob demanda) e registrar o modelo.
- Fazer o **deploy** como **Endpoint** (tempo real) e/ou **Batch Transform**.
- A diferença de custo entre manter um **Endpoint** vs rodar em lote.

## Como este lab funciona

1. O instrutor faz uma **demo ao vivo** no console do SageMaker.
2. Você repete seguindo o [passo a passo](passo-a-passo.md): no **console** e no
   **notebook da turma**. O [passo 5b](passo-a-passo.md) refaz o ciclo todo por
   **script AWS CLI** (caminho principal dele).
3. Os demais passos têm o **script AWS CLI** recolhido, para travas ou para ganhar tempo.
4. Encontrou algo errado? [Abra uma issue](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BPDN+Lab+03%5D+&labels=lab).

## Pré-requisitos

| Item | Valor |
|---|---|
| Conta AWS | com acesso ao Console e à AWS CLI |
| Tipo de usuário | **IAM** (não use o usuário root) |
| Região | `us-east-1` (ajuste se sua turma usar outra) |
| Serviços | Amazon SageMaker, Amazon S3, IAM |
| Pré-requisito | uma **execution role** do SageMaker com acesso ao S3 |
| Ferramentas | AWS CLI v2; o notebook do lab (link nas instruções da turma) |

## Custo estimado

> **Atenção ao Endpoint.** Notebook e Training Job custam por segundo de uso
> (instância pequena, poucos minutos → centavos). **O Endpoint em tempo real
> cobra enquanto estiver no ar** — é o maior risco de custo do curso. Estime
> **~US$ 0,50–1,00** se você apagar o Endpoint logo. **Delete o Endpoint ao
> terminar.**

## Tempo estimado

**1h35**: ~5 min de demo ao vivo do instrutor + ~1h30 de prática.

## Resultado esperado

Um modelo treinado no SageMaker e servido (Endpoint ou Batch Transform),
retornando predições.

## Ponto de parada seguro

Se o tempo acabar, pare com o **Training Job concluído** e o modelo registrado.
O deploy em **Endpoint** pode virar demonstração (e evita custo de endpoint
ocioso).

## Limpeza

**O Endpoint é o que mais cobra: apague primeiro.** Depois, o restante.

**No console** ([Amazon SageMaker](https://console.aws.amazon.com/sagemaker/)):

1. **Inference > Endpoints:** selecione o Endpoint e clique em **Actions > Delete**
   (ou **Delete**). Confirme que a lista ficou vazia.
2. **Inference > Endpoint configurations:** apague a configuração do endpoint.
3. **Inference > Models:** apague o modelo.
4. **Notebooks** (ou **Studio**): se criou uma Notebook Instance, selecione e use
   **Actions > Stop** (e, se não for mais usar, **Delete**). Se usou Studio, pare
   os apps/espaços em execução.
5. [Amazon S3](https://console.aws.amazon.com/s3/): selecione o seu bucket, clique
   em **Empty** e depois em **Delete**. No modo turma, apague só a sua pasta
   (`$ALUNO/`) dentro do bucket da turma.

> ⚠️ **Aviso (modo turma):** o bucket da turma é compartilhado. Antes de apagar
> qualquer coisa nele, confirme com o instrutor a regra de limpeza da sua turma e
> **nunca apague pastas de outros alunos**. Os Endpoints, modelos e jobs que **você**
> criou (prefixo com o seu usuário) são sempre seus para apagar.

<details>
<summary>⚡ Prefere o terminal (AWS CLI)? Clique para ver o script</summary>

```bash
# O ENDPOINT é o que mais cobra — apague primeiro
aws sagemaker delete-endpoint --endpoint-name <ENDPOINT>
aws sagemaker delete-endpoint-config --endpoint-config-name <CONFIG>
aws sagemaker delete-model --model-name <MODELO>
# pare/instancias de notebook, se criou via NotebookInstance
# aws sagemaker stop-notebook-instance --notebook-instance-name <NB>
aws s3 rm s3://SEU-BUCKET/ --recursive
```

</details>

## O que isso prova

Que o caminho do **notebook à produção** pode ser todo gerenciado: a mesma
infraestrutura que treina também serve o modelo, com pagamento por uso. E que a
escolha **Endpoint (tempo real) vs Batch** é, no fundo, uma decisão de custo e
latência.
