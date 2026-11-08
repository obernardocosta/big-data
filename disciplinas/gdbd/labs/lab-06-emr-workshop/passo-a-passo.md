# Lab 06 — Passo a passo

> **Como usar este roteiro**
>
> 1. Assista à **demo ao vivo** do instrutor (ele mostra a criação do cluster no
>    console, passo 3, uma vez).
> 2. Repita você mesmo **no console da AWS**, seguindo as instruções de cada passo.
> 3. Travou ou está sem tempo? Os passos têm um bloco **"Prefere o terminal?"**
>    (recolhido) com o mesmo passo em **AWS CLI**. Clique para abrir. A
>    preparação (passo 1) e a conexão **SSH** (passo 5b.4) usam o script como
>    caminho principal, e o texto explica por quê.

> **Custo:** o passo 3 **sobe o cluster** e aí começa a cobrança (~US$ 1 total).
> O cluster é criado com encerramento automático (transient): some sozinho ao
> acabar os steps. Ainda assim, confira a limpeza.

**Console da AWS:** <https://console.aws.amazon.com/> · região **N. Virginia
(`us-east-1`)**, confira no canto superior direito. O serviço do lab é o
[Amazon EMR](https://console.aws.amazon.com/emr/).

Os passos de script rodam no terminal ou no
[AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1)
(terminal no navegador, já com a AWS CLI e o Python). Defina as variáveis:

```bash
export BUCKET="gdbd-lab06-$(whoami)-$RANDOM"
export REGION="us-east-1"
# SSH no cluster e opcional e este lab nao precisa dele. Se quiser, veja a nota
# no passo 3 (a chave precisa EXISTIR na regiao, senao o cluster falha).
echo "$BUCKET"   # anote este nome: você vai usá-lo nos passos seguintes
```

> **Antes de começar, confira a quota.** Cada cluster do lab usa 2 × `m5.xlarge`
> = 8 vCPUs. Em [Service Quotas > EC2](https://console.aws.amazon.com/servicequotas/home/services/ec2/quotas),
> procure **Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances**
> (código `L-1216C47A`) e veja se o valor aplicado é de pelo menos 8 vCPUs.

## 1. Preparar dados e script no S3

**Porquê:** com EMRFS, o cluster lê/escreve no S3. Dados e código ficam lá, o
cluster é descartável.

Este passo é **preparação**, não conceito do lab: gerar o CSV a partir do JSON
(com `curl` + Python) e escrever o `etl.py` não têm equivalente simples no
console. Por isso aqui o **script é o caminho principal** (ele também cria o
bucket no [Amazon S3](https://console.aws.amazon.com/s3/)):

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

# CSV cru REAL: Premier League 2024/25 (openfootball, cópia no repo data)
curl -s https://raw.githubusercontent.com/obernardocosta/data/main/football/premier-league/2024-25/en.1.json \
  | python3 -c "
import json,sys,csv
dados=json.load(sys.stdin); w=csv.writer(sys.stdout)
w.writerow(['Date','HomeTeam','AwayTeam','FTHG','FTAG'])
for m in dados['matches']:
    ft=(m.get('score') or {}).get('ft') or [None,None]
    w.writerow([m.get('date'),m.get('team1'),m.get('team2'),ft[0],ft[1]])
" > premier.csv
aws s3 cp premier.csv "s3://$BUCKET/raw/premier.csv"

cat > etl.py <<'PY'
from pyspark.sql import SparkSession
import sys
spark = SparkSession.builder.appName("lab06-emr").getOrCreate()
df = (spark.read.option("header", True).csv(sys.argv[1])
      .select("Date", "HomeTeam", "AwayTeam", "FTHG", "FTAG"))
df.write.mode("overwrite").option("compression", "gzip").parquet(sys.argv[2])
spark.stop()
PY
aws s3 cp etl.py "s3://$BUCKET/scripts/etl.py"
```

**Como saber que deu certo:** no S3, o seu bucket tem `raw/premier.csv` e
`scripts/etl.py`.

## 2. Garantir as roles de serviço do EMR

**Porquê:** o EMR precisa de duas roles padrão (uma para o serviço, outra para
as instâncias EC2). Criá-las não gera custo.

**No console:**

1. No [IAM](https://console.aws.amazon.com/iam/) > **Roles**, procure por
   `EMR_DefaultRole` e `EMR_EC2_DefaultRole`. Se as duas já existem, siga para o
   passo 3.
2. Se não existem, o assistente **Create cluster** do passo 3 oferece criá-las
   (em **Security configuration and permissions**, opções do tipo
   **Create a service role** e **Create an instance profile**, dependendo da
   versão do console). Também dá para criá-las pelo script abaixo.

**Como saber que deu certo:** as duas roles aparecem na lista de Roles do IAM.
Se acabaram de nascer, espere cerca de 20 segundos antes do passo 3 (propagação
do IAM).

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws emr create-default-roles

# Na 1a vez, as roles e o instance profile acabaram de nascer e levam alguns
# segundos para propagar no IAM. Sem esta pausa o create-cluster do passo 3
# falha com "Invalid InstanceProfile: EMR_EC2_DefaultRole" (visto no teste real).
sleep 20
```

</details>

## 3. Subir um cluster TRANSIENT com um step de ETL (AQUI começa o custo)

**Porquê:** este é o ponto do lab. O encerramento automático faz o cluster se
encerrar ao fim dos steps — o padrão econômico (transient). Usamos poucas
instâncias pequenas para manter perto de US$ 1.

**No console:**

1. Abra o [Amazon EMR](https://console.aws.amazon.com/emr/) e clique em
   **Create cluster** (em **EMR on EC2 > Clusters**, dependendo da versão do console).
2. **Name:** `lab06-emr-transient`.
3. **Amazon EMR release:** `emr-7.1.0`. Em **Application bundle**, escolha
   **Spark** (ou **Custom** e marque apenas Spark).
4. **Cluster configuration** (instance groups): **Primary** com 1 × `m5.xlarge` e
   **Core** com 1 × `m5.xlarge` (2 instâncias no total). **Remova** o grupo
   **Task**, se houver.
5. **Cluster termination:** marque a opção de **terminar o cluster após o último
   step** (*Terminate cluster after last step completes*, ou
   **Automatically terminate cluster after last step is completed**). Isso é o que
   o torna *transient*.
6. **Cluster logs:** marque **Publish cluster-specific logs to Amazon S3** e
   informe `s3://SEU-BUCKET/logs/` (troque `SEU-BUCKET` pelo valor de `$BUCKET`).
7. **Steps** (adicionar o ETL): clique em **Add step** e preencha:
   - **Type:** `Spark application` · **Name:** `ETL`
   - **Application location:** `s3://SEU-BUCKET/scripts/etl.py`
   - **Arguments:** `s3://SEU-BUCKET/raw/ s3://SEU-BUCKET/parquet/`
   - **Action if step fails:** `Continue`
8. **Security configuration and permissions:** deixe **EC2 key pair** vazio (o SSH
   é opcional; veja a nota abaixo), **Service role** `EMR_DefaultRole` e
   **Instance profile** `EMR_EC2_DefaultRole`.
9. Clique em **Create cluster**.

> **Quer SSH no master?** Escolha em **EC2 key pair** uma chave que **exista** em
> `us-east-1` (em [EC2 > Key Pairs](https://console.aws.amazon.com/ec2/home#KeyPairs)).
> Com um nome inexistente o cluster é aceito, mas morre em ~30 s com
> `VALIDATION_ERROR: The given SSH key name was invalid`.

**Como saber que deu certo:** a página do cluster mostra o status **Starting** e,
depois de alguns minutos, **Running** e **Terminating/Terminated** (ao fim do step).
Anote o **Cluster ID** (`j-...`).

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
CLUSTER_ID=$(aws emr create-cluster \
  --name "lab06-emr-transient" \
  --release-label emr-7.1.0 \
  --applications Name=Spark \
  --instance-type m5.xlarge --instance-count 2 \
  --use-default-roles \
  --auto-terminate \
  --log-uri "s3://$BUCKET/logs/" \
  --steps "Type=Spark,Name=ETL,ActionOnFailure=CONTINUE,Args=[s3://$BUCKET/scripts/etl.py,s3://$BUCKET/raw/,s3://$BUCKET/parquet/]" \
  --region "$REGION" --query 'ClusterId' --output text)

echo "Cluster: $CLUSTER_ID"
```

> **Quer SSH no master?** Acrescente `--ec2-attributes KeyName=SUA-CHAVE` ao
> comando, com uma chave que **exista** em `$REGION`
> (`aws ec2 describe-key-pairs --query 'KeyPairs[].KeyName'`). Com um nome
> inexistente o cluster é aceito, mas morre em ~30 s com
> `VALIDATION_ERROR: The given SSH key name was invalid`.

</details>

## 4. Acompanhar o cluster e o step

**Porquê:** validar que o ETL rodou. Como é transient, o cluster vai para
`TERMINATING` depois do step.

**No console:**

1. No [Amazon EMR](https://console.aws.amazon.com/emr/), abra o cluster
   `lab06-emr-transient` e veja o **Status** na aba **Summary**.
2. Abra a aba **Steps** e acompanhe o step `ETL`: `Pending` → `Running` →
   `Completed`.

**Como saber que deu certo:** o step `ETL` está **Completed** e, em seguida, o
cluster vai para **Terminating** e **Terminated**. Se o step der **Failed**, veja
os logs em `s3://SEU-BUCKET/logs/` e o [troubleshooting](troubleshooting.md).

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws emr describe-cluster --cluster-id "$CLUSTER_ID" \
  --query 'Cluster.Status.State'

aws emr list-steps --cluster-id "$CLUSTER_ID" \
  --query 'Steps[].{Nome:Name,Estado:Status.State}'
```

</details>

## 5. Conferir a saída no S3

**No console:** no [Amazon S3](https://console.aws.amazon.com/s3/), abra o seu
bucket > pasta `parquet/`.

**Como saber que deu certo:** a pasta tem arquivos `part-...parquet` (e um
`_SUCCESS`).

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
aws s3 ls "s3://$BUCKET/parquet/" --recursive
```

</details>

## 5b. Workshop interativo: entrar no cluster e explorar com Spark

**Porquê:** o cluster transient do passo 3 é o jeito certo de rodar ETL em
produção, mas ele some ao terminar o step: não dá para "entrar" nele. Aqui você
sobe um cluster **long running**, entra no master por SSH e usa o Spark de
forma interativa sobre o Parquet que o passo 3 gerou no S3. É a hora de ver
Master/Core, YARN e EMRFS funcionando.

> **Custo:** este cluster fica ligado até você encerrar. Ele tem uma rede de
> segurança (desliga sozinho após 1 h ocioso), mas **encerre ao terminar**
> (passo 5b.5). ~US$ 0,50 por hora.

> **Espere o cluster do passo 3 chegar em `Terminated` antes de subir este.**
> Cada cluster usa 2 × m5.xlarge = 8 vCPUs, e contas novas costumam ter quota
> de **8 vCPUs** On-Demand (confira a sua em
> [Service Quotas > EC2](https://console.aws.amazon.com/servicequotas/home/services/ec2/quotas)).
> Com os dois ligados ao mesmo tempo, o segundo falha por falta de capacidade.

### 5b.1 Criar seu par de chaves (fica só com você)

**Porquê:** o SSH no EMR autentica por chave. A parte privada (`.pem`) é baixada
uma única vez e fica só com você.

**No console:**

1. Abra [EC2 > Key Pairs](https://console.aws.amazon.com/ec2/home#KeyPairs) e
   clique em **Create key pair**.
2. **Name:** `lab06-seunome` · **Key pair type:** RSA · **Private key file
   format:** `.pem`. Clique em **Create key pair**; o download começa na hora.
3. Mova o arquivo para a pasta onde vai rodar o `ssh` e proteja-o:
   `chmod 400 lab06-seunome.pem` (o `ssh` recusa chave com permissão aberta).
4. No terminal, defina `export KEYNAME="lab06-seunome"` (o mesmo nome usado acima).

**Como saber que deu certo:** a chave aparece em **Key Pairs** e o arquivo `.pem`
está na sua máquina.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
export KEYNAME="lab06-$(whoami)"
aws ec2 create-key-pair --key-name "$KEYNAME" \
  --query KeyMaterial --output text > "$KEYNAME.pem"
chmod 400 "$KEYNAME.pem"     # o ssh recusa chave com permissao aberta
```

</details>

### 5b.2 Subir o cluster long running com a chave

**Porquê:** diferente do passo 3, este cluster **não** termina sozinho ao fim dos
steps: fica de pé (*long running*) para você entrar nele.

**No console:**

1. No [Amazon EMR](https://console.aws.amazon.com/emr/), clique em **Create cluster**.
2. **Name:** `lab06-emr-interativo` · **Release:** `emr-7.1.0` · **Application
   bundle:** Spark.
3. **Cluster configuration:** **Primary** 1 × `m5.xlarge` e **Core** 1 × `m5.xlarge`;
   remova o grupo **Task**.
4. **Cluster termination:** escolha o encerramento automático por **ociosidade**
   (*Terminate cluster after idle time*, ou **Use automatic termination**) com
   **1 hora** (3600 s). **Não** marque terminar após o último step.
5. **Cluster logs:** `s3://SEU-BUCKET/logs/`.
6. **Security configuration and permissions:** em **EC2 key pair**, selecione a
   chave do passo 5b.1; service role e instance profile padrão
   (`EMR_DefaultRole` / `EMR_EC2_DefaultRole`).
7. Clique em **Create cluster** e espere o status **Waiting** (~5 min, "Cluster
   ready to run steps").

**Como saber que deu certo:** o status do cluster é **Waiting**. Anote o
**Cluster ID** (`j-...`).

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
CLUSTER_ID2=$(aws emr create-cluster \
  --name "lab06-emr-interativo" \
  --release-label emr-7.1.0 \
  --applications Name=Spark \
  --instance-type m5.xlarge --instance-count 2 \
  --use-default-roles \
  --ec2-attributes KeyName="$KEYNAME" \
  --auto-termination-policy IdleTimeout=3600 \
  --log-uri "s3://$BUCKET/logs/" \
  --region "$REGION" --query 'ClusterId' --output text)

# ~5 min ate WAITING ("Cluster ready to run steps")
aws emr describe-cluster --cluster-id "$CLUSTER_ID2" \
  --query 'Cluster.Status.State'
```

</details>

### 5b.3 Liberar o SSH só para o seu IP

**Porquê:** por padrão o security group do master **não** aceita SSH da
internet. Sem este passo o `ssh` fica parado e termina em `Operation timed out`.
Liberamos só o seu IP (`/32`), nunca `0.0.0.0/0`.

**No console:**

1. Na página do cluster ([Amazon EMR](https://console.aws.amazon.com/emr/)), aba
   **Summary** (ou **Properties**), anote o **Primary node public DNS**
   (`ec2-...amazonaws.com`).
2. Na mesma página, em **Network and security** (ou **EC2 security groups
   (firewall)**), clique no link do security group do **Primary node**
   (`ElasticMapReduce-master`).
3. Em [EC2 > Security Groups](https://console.aws.amazon.com/ec2/home#SecurityGroups),
   aba **Inbound rules**, clique em **Edit inbound rules** > **Add rule**:
   **Type** `SSH` (porta 22) · **Source** `My IP`. Salve.
4. No terminal, defina `export MASTER_DNS="<o DNS anotado>"`.

**Como saber que deu certo:** o security group do master tem uma regra de entrada
`SSH / 22` com o **seu IP** `/32` (e **não** `0.0.0.0/0`).

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
export MASTER_DNS=$(aws emr describe-cluster --cluster-id "$CLUSTER_ID2" \
  --query 'Cluster.MasterPublicDnsName' --output text)
export MASTER_SG=$(aws emr describe-cluster --cluster-id "$CLUSTER_ID2" \
  --query 'Cluster.Ec2InstanceAttributes.EmrManagedMasterSecurityGroup' --output text)
export MYIP=$(curl -s https://checkip.amazonaws.com)

aws ec2 authorize-security-group-ingress --group-id "$MASTER_SG" \
  --protocol tcp --port 22 --cidr "${MYIP}/32"
```

</details>

### 5b.4 Entrar e explorar

**Porquê:** é aqui que você vê o cluster por dentro: YARN, os Core Nodes e o
Spark lendo o Parquet direto do S3 (EMRFS).

Este passo é uma **sessão SSH interativa**, que não tem equivalente no console.
Por isso o **script é o caminho principal**. Rode no seu terminal (o
[AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home?region=us-east-1)
também serve, mas você precisa enviar o `.pem` para ele):

```bash
ssh -i "$KEYNAME.pem" hadoop@"$MASTER_DNS"
```

Já dentro do master:

```bash
yarn node -list          # os Core Nodes que executam o trabalho
spark-sql -S -e "
  SELECT HomeTeam AS time, SUM(CAST(FTHG AS INT)) AS gols_casa
  FROM parquet.\`s3://SEU-BUCKET/parquet/\`
  GROUP BY HomeTeam ORDER BY gols_casa DESC LIMIT 5"
# ou abra o shell interativo:  pyspark
```

**Como saber que deu certo:** resultado esperado (dados reais 2024/25):
Manchester City FC 43, Liverpool FC 42, Newcastle United FC 40, Brentford FC
40… O mesmo número que o Athena deu no Lab 03: o dado mora no S3 e **qualquer
motor** lê.

> Antes do resultado, o `spark-sql` imprime várias linhas `WARN` (HiveConf,
> ObjectStore, `spark.yarn.jars`...). São normais num cluster novo: ignore e
> procure o ranking no fim da saída. A primeira consulta leva ~30 s porque o
> Spark sobe os executores no YARN.

### 5b.5 Encerrar e limpar (não pule)

**Porquê:** este cluster é cobrado enquanto estiver ligado. Encerre também o
acesso (regra do security group e chave).

**No console:**

1. No terminal, saia do master com `exit`.
2. [Amazon EMR](https://console.aws.amazon.com/emr/): selecione
   `lab06-emr-interativo` e clique em **Terminate** (confirme).
3. [EC2 > Security Groups](https://console.aws.amazon.com/ec2/home#SecurityGroups):
   no security group do master, **Edit inbound rules** e **apague** a regra SSH
   do seu IP. Salve.
4. [EC2 > Key Pairs](https://console.aws.amazon.com/ec2/home#KeyPairs): selecione a
   chave `lab06-...` e **Actions > Delete**. Apague também o `.pem` local
   (`rm -f lab06-seunome.pem`).

**Como saber que deu certo:** o cluster aparece como **Terminated** e a lista de
clusters ativos fica vazia.

<details>
<summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

```bash
exit   # sai do master
aws emr terminate-clusters --cluster-ids "$CLUSTER_ID2"
aws ec2 revoke-security-group-ingress --group-id "$MASTER_SG" \
  --protocol tcp --port 22 --cidr "${MYIP}/32"
aws ec2 delete-key-pair --key-name "$KEYNAME"
rm -f "$KEYNAME.pem"
```

</details>

## 6. (Extra/desafio) Orquestrar com Step Functions

**Porquê:** liga a Aula 4 (orquestração) ao EMR. A ideia: uma Step Function que
cria o cluster, adiciona o step e aguarda o término.

- No console do [AWS Step Functions](https://console.aws.amazon.com/states/),
  monte uma máquina de estados com os estados
  `createCluster → addStep → (sync) → terminateCluster`.
- **Desafio:** fazer funcionar **sem** solicitar o template pronto — montando a
  partir da documentação dos
  [conectores de EMR no Step Functions](https://docs.aws.amazon.com/step-functions/latest/dg/connect-emr.html).

## Limpeza

> **Não deixe cluster ligado: é ele que gera custo.** Como o cluster do passo 3 é
> transient, ele some ao fim dos steps, mas confira. Siga a seção
> [**Limpeza** do README deste lab](https://github.com/obernardocosta/big-data/blob/main/disciplinas/gdbd/labs/lab-06-emr-workshop/README.md#limpeza).

## Encontrou um problema neste lab?

Um passo não bate com o que você vê no console, um menu mudou de nome ou algo
deu erro? **Abra uma issue** e ajude a melhorar a disciplina:
[abrir issue sobre o GDBD Lab 06](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml&title=%5BGDBD+Lab+06%5D+&labels=lab).
Diga o passo, o que esperava e o que aconteceu (um print ajuda).
