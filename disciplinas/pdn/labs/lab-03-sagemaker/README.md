# Lab 02 (PDN) — Amazon SageMaker (treino + deploy)

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

**1h30.**

## Resultado esperado

Um modelo treinado no SageMaker e servido (Endpoint ou Batch Transform),
retornando predições.

## Ponto de parada seguro

Se o tempo acabar, pare com o **Training Job concluído** e o modelo registrado.
O deploy em **Endpoint** pode virar demonstração (e evita custo de endpoint
ocioso).

## Limpeza

```bash
# O ENDPOINT é o que mais cobra — apague primeiro
aws sagemaker delete-endpoint --endpoint-name <ENDPOINT>
aws sagemaker delete-endpoint-config --endpoint-config-name <CONFIG>
aws sagemaker delete-model --model-name <MODELO>
# pare/instancias de notebook, se criou via NotebookInstance
# aws sagemaker stop-notebook-instance --notebook-instance-name <NB>
aws s3 rm s3://SEU-BUCKET/ --recursive
```

## O que isso prova

Que o caminho do **notebook à produção** pode ser todo gerenciado: a mesma
infraestrutura que treina também serve o modelo, com pagamento por uso. E que a
escolha **Endpoint (tempo real) vs Batch** é, no fundo, uma decisão de custo e
latência.
