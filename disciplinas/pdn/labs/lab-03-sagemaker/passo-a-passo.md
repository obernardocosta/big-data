# PDN Lab 03 (Lab C) — Passo a passo

> **Como usar este roteiro**
>
> 1. Assista à **demo ao vivo** do instrutor (ele mostra o ciclo no console do
>    SageMaker: Training Job e Endpoint/Batch Transform).
> 2. Repita você mesmo **no console da AWS** e no **notebook da turma**,
>    seguindo as instruções de cada passo.
> 3. Travou ou está sem tempo? Os passos com console têm um bloco **"Prefere o
>    terminal?"** (recolhido) com o mesmo passo em **AWS CLI**, e o **passo 5b**
>    refaz o ciclo inteiro por script.
>
> ⚠️ **Aviso:** a AWS muda nomes de menus e botões com frequência. Se algo não
> estiver exatamente como descrito, procure pelo **objetivo** do passo, use o
> script recolhido ou abra uma issue (link no fim). Isso também ajuda os próximos alunos.

> **Custo:** Training Job cobra por segundo de instância; **o Endpoint cobra
> enquanto estiver no ar**. Use instâncias pequenas e **apague o Endpoint** ao
> final.

**Console da AWS:** <https://console.aws.amazon.com/> · região **N. Virginia
(`us-east-1`)**, confira no canto superior direito. Console do serviço:
[Amazon SageMaker](https://console.aws.amazon.com/sagemaker/).

O lab segue o **notebook disponibilizado pela turma** (passos 2 a 5). O que o
notebook faz com o SDK, você acompanha no **console do SageMaker**. Os comandos
em script mostram o fluxo conceitual (via SDK/CLI) para quem quiser reproduzir
fora do notebook.

## Modo turma (conta do instrutor) — use este se recebeu usuário e senha

**Porquê:** conta AWS nova vem com quota **0** para treinar no SageMaker, e o
pedido de aumento leva dias. Por isso o instrutor libera um acesso temporário
na conta dele, já com quota. Seu usuário só enxerga os **seus** recursos, só usa
instâncias pequenas e expira sozinho no fim do curso.

1. Entre no link de login que você recebeu, com seu usuário e senha.
2. Depois do login, abra o **CloudShell** já na região certa:
   [AWS CloudShell (us-east-1)](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1)
   (o console abre em Ohio, `us-east-2`, por padrão; o lab é em N. Virginia,
   `us-east-1`). É um terminal no navegador, com a AWS CLI e o Python prontos:
   não precisa instalar nada. Na primeira vez ele leva ~1 min para iniciar.
3. Cole as duas linhas que o instrutor passou (`TURMA_BUCKET` e `SM_ROLE`) e,
   em seguida:

```bash
# seu nome de usuario vira o prefixo de tudo que voce criar
export ALUNO="$(aws sts get-caller-identity --query Arn --output text | cut -d/ -f2)"
export REGION="us-east-1"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export BUCKET="$TURMA_BUCKET/$ALUNO"     # sua pasta no bucket da turma
echo "Aluno: $ALUNO | dados em s3://$BUCKET"
```

4. **Pule** o bloco de variáveis abaixo e o passo 1 (o bucket e a role já
   existem) e vá direto ao **passo 5b**. Use os nomes como estão: o `JOB`
   começa com o seu usuário, e é isso que a sua permissão exige.

> Se aparecer `AccessDenied` / `not authorized`: confira se o nome do recurso
> começa com `$ALUNO-`, se o tipo de instância é `ml.m5.large` e se o endpoint
> é serverless. São as travas que mantêm o lab barato.

**Fora do modo turma** (na sua própria conta), siga a partir daqui. Se for usar o
terminal ou o CloudShell, defina as variáveis:

```bash
export BUCKET="pdn-lab03-$(whoami)-$RANDOM"
export REGION="us-east-1"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export SM_ROLE="SageMakerExecutionRole"
```

## 1. Pré-requisitos: bucket e execution role

**Porquê:** o SageMaker usa uma **execution role** para ler dados e gravar
artefatos de modelo no S3. É ela que o Training Job e o Endpoint assumem.

**No console:**

1. Crie o bucket no [Amazon S3](https://console.aws.amazon.com/s3/) > **Create
   bucket**, com o nome que você definiu em `BUCKET` (ex.:
   `pdn-lab03-seunome-1234`), região `us-east-1`, restante padrão.
2. Abra o [IAM](https://console.aws.amazon.com/iam/) > **Roles > Create role**.
3. **Trusted entity type:** **AWS service**; em **Use case**, escolha
   **SageMaker** (ou **SageMaker - Execution**, dependendo da versão do
   console). Avance.
4. Confirme/adicione as policies `AmazonSageMakerFullAccess` e
   `AmazonS3FullAccess`. Avance.
5. **Role name:** `SageMakerExecutionRole`. Clique em **Create role**.
6. Aguarde ~15 segundos antes de usar a role: role recém-criada leva alguns
   segundos para propagar no IAM.

**Como saber que deu certo:** o bucket aparece no S3 e a role
`SageMakerExecutionRole` aparece em **Roles**, com as duas policies anexadas.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

cat > trust-sm.json <<'JSON'
{ "Version": "2012-10-17",
  "Statement": [{ "Effect": "Allow",
    "Principal": {"Service": "sagemaker.amazonaws.com"},
    "Action": "sts:AssumeRole" }] }
JSON
aws iam create-role --role-name "$SM_ROLE" \
  --assume-role-policy-document file://trust-sm.json
aws iam attach-role-policy --role-name "$SM_ROLE" \
  --policy-arn arn:aws:iam::aws:policy/AmazonSageMakerFullAccess
aws iam attach-role-policy --role-name "$SM_ROLE" \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# role recem-criada leva alguns segundos para propagar no IAM; sem esta pausa
# o primeiro Training Job falha com "The AWS Access Key Id you provided does
# not exist in our records" (visto no teste real)
sleep 15
```

</details>

## 2. Manipulação dos dados (Notebook)

**Porquê:** primeira etapa do ML (Data Wrangling). No Notebook gerenciado, você
prepara os dados e sobe o dataset de treino para o S3.

**No notebook (caminho principal deste passo):**

- Abra o **notebook do lab** (link nas instruções da turma). Se precisar abrir o
  ambiente de notebooks, use o [console do SageMaker](https://console.aws.amazon.com/sagemaker/)
  (**Notebooks** ou **Studio**, dependendo da versão do console) e escolha a
  execution role do passo 1.
- Execute as células de preparação, que gravam o dataset em
  `s3://$BUCKET/input/`.

**Como saber que deu certo:** no [Amazon S3](https://console.aws.amazon.com/s3/),
a pasta `input/` do seu bucket tem o dataset de treino.

## 3. Treinamento do modelo (Training Job)

**Porquê:** o SageMaker provisiona a instância de treino **sob demanda**, roda o
algoritmo e salva o artefato do modelo no S3 — sem você gerenciar servidor/GPU.

**No notebook (caminho principal deste passo):**

- Use o Estimator do SDK (`sagemaker.estimator.Estimator` ou um algoritmo
  built-in) apontando entrada para `s3://$BUCKET/input/` e saída para
  `s3://$BUCKET/model/`. O `fit()` dispara o Training Job.

**No console:** acompanhe o job no [console do SageMaker](https://console.aws.amazon.com/sagemaker/),
em **Training > Training jobs** (ou **Jobs > Training**, dependendo da versão).
O status vai de **InProgress** a **Completed**.

**Como saber que deu certo:** o Training Job fica **Completed** e há um
`model.tar.gz` em `s3://$BUCKET/model/`.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script de acompanhamento</summary>

```bash
aws sagemaker list-training-jobs --max-results 5 \
  --query 'TrainingJobSummaries[].{Nome:TrainingJobName,Estado:TrainingJobStatus}'
```

</details>

## 4. Deploy do modelo

**Porquê:** servir o modelo. Duas opções (Aula 2):

- **Endpoint (tempo real)** — `estimator.deploy(...)` cria um endpoint que
  responde requisição a requisição. **Cobra enquanto existir.**
- **Batch Transform** — inferência em lote sobre um dataset, sem endpoint
  permanente (melhor para custo quando não precisa de tempo real).

**No notebook:** siga as células de deploy do notebook da turma, na opção que o
instrutor indicar (o lab recomenda **Batch Transform**).

**No console:** veja o resultado em **Inference > Endpoints** (para Endpoint) ou
**Inference > Batch transform jobs** (para Batch Transform), no
[console do SageMaker](https://console.aws.amazon.com/sagemaker/). O nome do menu
pode variar um pouco dependendo da versão do console.

**Como saber que deu certo:** o Endpoint fica **InService** (leva alguns
minutos) ou o Batch Transform job fica **Completed**.

## 5. Testar a inferência

**Porquê:** fechar o ciclo: dado novo entra, o modelo devolve uma predição.

**No notebook:** execute a célula de predição (`predictor.predict(amostra)` no
caso do Endpoint) ou leia a saída do Batch Transform no S3.

**No console:** em **Inference > Endpoints**, confira que o Endpoint está
**InService**.

**Como saber que deu certo:** a predição volta com valores plausíveis (por
exemplo, uma probabilidade entre 0 e 1).

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
# exemplo conceitual (via SDK no notebook): predictor.predict(amostra)
aws sagemaker list-endpoints \
  --query 'Endpoints[].{Nome:EndpointName,Estado:EndpointStatus}'
```

</details>

## 5b. Caminho reproduzível via CLI (testado em 2026-11-08)

**Porquê:** o mesmo ciclo dados → Training Job → deploy, sem depender do
notebook da turma. Útil para o instrutor validar a conta na véspera e para quem
quiser refazer em casa. Custo medido: centavos (treino de ~2 min em
`ml.m5.large`, endpoint **serverless**, que não cobra parado).

Este caminho é **todo por script** (gerar o dataset com `curl` + Python e criar
Training Job, modelo e endpoint por CLI não têm equivalente simples no console),
então o **script é o caminho principal**. Rode no terminal ou no
[AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1).
Em paralelo, **acompanhe tudo no console do SageMaker**: **Training jobs**,
**Models**, **Endpoints** e **Batch transform jobs** (menus em **Training** e
**Inference**, dependendo da versão do console).

```bash
# dataset: o mandante venceu (1/0)? features = media de gols pro/contra de
# cada time nos jogos ANTERIORES (dados reais 2024/25, openfootball via repo data)
curl -s https://raw.githubusercontent.com/obernardocosta/data/main/football/premier-league/2024-25/en.1.json \
  | python3 -c "
import json,sys,csv,collections
ms=sorted(json.load(sys.stdin)['matches'],key=lambda m:m['date'])
gf=collections.defaultdict(list); ga=collections.defaultdict(list)
avg=lambda l: sum(l)/len(l) if l else 1.4
rows=[]
for m in ms:
    ft=(m.get('score') or {}).get('ft')
    if not ft: continue
    h,a=m['team1'],m['team2']
    rows.append([1 if ft[0]>ft[1] else 0, round(avg(gf[h]),3), round(avg(ga[h]),3), round(avg(gf[a]),3), round(avg(ga[a]),3)])
    gf[h].append(ft[0]); ga[h].append(ft[1]); gf[a].append(ft[1]); ga[a].append(ft[0])
csv.writer(open('train.csv','w')).writerows(rows[:300])            # rotulo na 1a coluna
csv.writer(open('test.csv','w')).writerows([r[1:] for r in rows[300:]])
"
aws s3 cp train.csv "s3://$BUCKET/input/train/train.csv"
aws s3 cp test.csv  "s3://$BUCKET/input/test/test.csv"

# Training Job com o XGBoost nativo do SageMaker
export IMAGE="683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1"
export JOB="${ALUNO:-pdn}-labc-$(date +%H%M%S)"   # no modo turma: <seu-usuario>-labc-...
aws sagemaker create-training-job --training-job-name "$JOB" \
  --algorithm-specification TrainingImage=$IMAGE,TrainingInputMode=File \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/$SM_ROLE" \
  --input-data-config "[{\"ChannelName\":\"train\",\"ContentType\":\"text/csv\",\"DataSource\":{\"S3DataSource\":{\"S3DataType\":\"S3Prefix\",\"S3Uri\":\"s3://$BUCKET/input/train/\",\"S3DataDistributionType\":\"FullyReplicated\"}}}]" \
  --output-data-config "S3OutputPath=s3://$BUCKET/model/" \
  --resource-config InstanceType=ml.m5.large,InstanceCount=1,VolumeSizeInGB=5 \
  --stopping-condition MaxRuntimeInSeconds=900 \
  --hyper-parameters objective=binary:logistic,num_round=50,max_depth=3
```

**Espere o treino terminar** (~3 min: `Starting → Downloading → Training →
Uploading → Completed`). No console, veja o status em **Training jobs**. Pelo
terminal, repita até ver `Completed`:

```bash
aws sagemaker describe-training-job --training-job-name "$JOB" \
  --query '[TrainingJobStatus,SecondaryStatus]'
```

Com o treino concluído, registre o modelo e suba o endpoint:

```bash
# Modelo + endpoint SERVERLESS (cobra por requisicao, nao por hora)
ART=$(aws sagemaker describe-training-job --training-job-name "$JOB" \
  --query ModelArtifacts.S3ModelArtifacts --output text)
aws sagemaker create-model --model-name "$JOB-model" \
  --execution-role-arn "arn:aws:iam::${ACCOUNT_ID}:role/$SM_ROLE" \
  --primary-container "Image=$IMAGE,ModelDataUrl=$ART"
aws sagemaker create-endpoint-config --endpoint-config-name "$JOB-cfg" \
  --production-variants "VariantName=v1,ModelName=$JOB-model,ServerlessConfig={MemorySizeInMB=2048,MaxConcurrency=1}"
aws sagemaker create-endpoint --endpoint-name "$JOB-ep" --endpoint-config-name "$JOB-cfg"
```

**Espere o endpoint** ficar `InService` (~3 min; repita). No console, veja em
**Endpoints**:

```bash
aws sagemaker describe-endpoint --endpoint-name "$JOB-ep" --query EndpointStatus
```

```bash
# Predicao em tempo real: probabilidade de vitoria do mandante
head -1 test.csv > amostra.csv
aws sagemaker-runtime invoke-endpoint --endpoint-name "$JOB-ep" \
  --content-type text/csv --body fileb://amostra.csv pred.json && cat pred.json

# (opcional) Batch Transform: as 80 predicoes de uma vez, sem endpoint
aws sagemaker create-transform-job --transform-job-name "$JOB-batch" \
  --model-name "$JOB-model" \
  --transform-input "DataSource={S3DataSource={S3DataType=S3Prefix,S3Uri=s3://$BUCKET/input/test/}},ContentType=text/csv,SplitType=Line" \
  --transform-output "S3OutputPath=s3://$BUCKET/batch-out/" \
  --transform-resources InstanceType=ml.m5.large,InstanceCount=1
```

**Como saber que deu certo:** o `pred.json` traz a probabilidade de vitória do
mandante; no console, o Endpoint aparece **InService** e o Batch Transform
(opcional) **Completed**, com a saída em `batch-out/` no S3.

> **Para discutir com a turma:** com só essas 4 features o modelo acerta ~57%,
> o mesmo que "chutar sempre a classe mais comum". O lab prova a
> **infraestrutura** (treinar, servir, escalar a zero); melhorar o modelo
> (mais features, mais temporadas) é o exercício seguinte.

Limpeza deste caminho: `delete-endpoint --endpoint-name "$JOB-ep"`,
`delete-endpoint-config --endpoint-config-name "$JOB-cfg"` e
`delete-model --model-name "$JOB-model"`, mais o bucket (passo 6).

## 6. LIMPEZA (faça antes de sair!)

**Porquê:** o **Endpoint** é o maior risco de custo do curso — ele cobra parado.

Siga a seção
[**Limpeza** do README deste lab](https://github.com/obernardocosta/big-data/blob/main/disciplinas/pdn/labs/lab-03-sagemaker/README.md#limpeza),
que traz o passo a passo no console (e o script recolhido). Apague **primeiro o
Endpoint**, depois a configuração do endpoint, o modelo e os arquivos do bucket.

> ⚠️ **Modo turma:** o bucket é compartilhado. Confirme com o instrutor a regra de
> limpeza da sua turma e **nunca apague pastas de outros alunos**; apague só o que
> você criou.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws sagemaker delete-endpoint        --endpoint-name <ENDPOINT>
aws sagemaker delete-endpoint-config --endpoint-config-name <CONFIG>
aws sagemaker delete-model           --model-name <MODELO>
aws s3 rm "s3://$BUCKET/" --recursive
```

</details>

## Encontrou um problema neste lab?

Um passo não bate com o que você vê no console, um menu mudou de nome ou algo
deu erro? **Abra uma issue** e ajude a melhorar a disciplina:
[abrir issue sobre o PDN Lab 03](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BPDN+Lab+03%5D+&labels=lab).
Diga o passo, o que esperava e o que aconteceu (um print ajuda).
