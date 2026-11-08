# Lab 06 — Passo a passo

> Rode o `dry-run.sh` **reforçado** deste lab na véspera. Ele checa credencial,
> usuário IAM, roles do EMR, **capacidade/quota de EC2 na região** e o par de
> chaves — tudo read-only, **sem subir cluster**. Este é o lab que mais depende
> de preparação prévia.

> **Custo:** o passo 3 **sobe o cluster** e aí começa a cobrança (~US$ 1 total).
> O cluster é criado com `--auto-terminate` (transient): some sozinho ao acabar
> os steps. Ainda assim, confira a limpeza.

```bash
export BUCKET="gdbd-lab06-$(whoami)-$RANDOM"
export REGION="us-east-1"
# SSH no cluster e opcional e este lab nao precisa dele. Se quiser, veja a nota
# no passo 3 (a chave precisa EXISTIR na regiao, senao o cluster falha).
```

## 1. Preparar dados e script no S3

**Porquê:** com EMRFS, o cluster lê/escreve no S3. Dados e código ficam lá, o
cluster é descartável.

```bash
aws s3 mb "s3://$BUCKET" --region "$REGION"

# CSV cru REAL: Premier League 2024/25 (openfootball, sem API key)
curl -s https://raw.githubusercontent.com/openfootball/football.json/master/2024-25/en.1.json \
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

## 2. Garantir as roles de serviço do EMR

**Porquê:** o EMR precisa de duas roles padrão (uma para o serviço, outra para
as instâncias EC2). O comando abaixo cria as default se não existirem — não gera
custo.

```bash
aws emr create-default-roles

# Na 1a vez, as roles e o instance profile acabaram de nascer e levam alguns
# segundos para propagar no IAM. Sem esta pausa o create-cluster do passo 3
# falha com "Invalid InstanceProfile: EMR_EC2_DefaultRole" (visto no teste real).
sleep 20
```

## 3. Subir um cluster TRANSIENT com um step de ETL (AQUI começa o custo)

**Porquê:** este é o ponto do lab. `--auto-terminate` faz o cluster se encerrar
ao fim dos steps — o padrão econômico (transient). Usamos poucas instâncias
pequenas para manter perto de US$ 1.

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

## 4. Acompanhar o cluster e o step

**Porquê:** validar que o ETL rodou. Como é transient, o cluster vai para
`TERMINATING` depois do step.

```bash
aws emr describe-cluster --cluster-id "$CLUSTER_ID" \
  --query 'Cluster.Status.State'

aws emr list-steps --cluster-id "$CLUSTER_ID" \
  --query 'Steps[].{Nome:Name,Estado:Status.State}'
```

## 5. Conferir a saída no S3

```bash
aws s3 ls "s3://$BUCKET/parquet/" --recursive
```

## 5b. Workshop interativo: entrar no cluster e explorar com Spark

**Porquê:** o cluster transient do passo 3 é o jeito certo de rodar ETL em
produção, mas ele some ao terminar o step: não dá para "entrar" nele. Aqui você
sobe um cluster **long running**, entra no master por SSH e usa o Spark de
forma interativa sobre o Parquet que o passo 3 gerou no S3. É a hora de ver
Master/Core, YARN e EMRFS funcionando.

> **Custo:** este cluster fica ligado até você encerrar. Ele tem uma rede de
> segurança (`IdleTimeout=3600`: desliga sozinho após 1 h ocioso), mas
> **encerre ao terminar** (passo 5b.5). ~US$ 0,50 por hora.

> **Espere o cluster do passo 3 chegar em `TERMINATED` antes de subir este.**
> Cada cluster usa 2 × m5.xlarge = 8 vCPUs, e contas novas costumam ter quota
> de **8 vCPUs** On-Demand (o `dry-run.sh` mostra a sua). Com os dois ligados ao
> mesmo tempo, o segundo falha por falta de capacidade.

### 5b.1 Criar seu par de chaves (fica só com você)

```bash
export KEYNAME="lab06-$(whoami)"
aws ec2 create-key-pair --key-name "$KEYNAME" \
  --query KeyMaterial --output text > "$KEYNAME.pem"
chmod 400 "$KEYNAME.pem"     # o ssh recusa chave com permissao aberta
```

### 5b.2 Subir o cluster long running com a chave

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

### 5b.3 Liberar o SSH só para o seu IP

**Porquê:** por padrão o security group do master **não** aceita SSH da
internet. Sem este passo o `ssh` fica parado e termina em `Operation timed out`.
Liberamos só o seu IP (`/32`), nunca `0.0.0.0/0`.

```bash
export MASTER_DNS=$(aws emr describe-cluster --cluster-id "$CLUSTER_ID2" \
  --query 'Cluster.MasterPublicDnsName' --output text)
export MASTER_SG=$(aws emr describe-cluster --cluster-id "$CLUSTER_ID2" \
  --query 'Cluster.Ec2InstanceAttributes.EmrManagedMasterSecurityGroup' --output text)
export MYIP=$(curl -s https://checkip.amazonaws.com)

aws ec2 authorize-security-group-ingress --group-id "$MASTER_SG" \
  --protocol tcp --port 22 --cidr "${MYIP}/32"
```

### 5b.4 Entrar e explorar

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

Resultado esperado (dados reais 2024/25): Manchester City FC 43, Liverpool FC
42, Newcastle United FC 40, Brentford FC 40… O mesmo número que o Athena deu no
Lab 03: o dado mora no S3 e **qualquer motor** lê.

> Antes do resultado, o `spark-sql` imprime várias linhas `WARN` (HiveConf,
> ObjectStore, `spark.yarn.jars`...). São normais num cluster novo: ignore e
> procure o ranking no fim da saída. A primeira consulta leva ~30 s porque o
> Spark sobe os executores no YARN.

### 5b.5 Encerrar e limpar (não pule)

```bash
exit   # sai do master
aws emr terminate-clusters --cluster-ids "$CLUSTER_ID2"
aws ec2 revoke-security-group-ingress --group-id "$MASTER_SG" \
  --protocol tcp --port 22 --cidr "${MYIP}/32"
aws ec2 delete-key-pair --key-name "$KEYNAME"
rm -f "$KEYNAME.pem"
```

## 6. (Extra/desafio) Orquestrar com Step Functions

**Porquê:** liga a Aula 4 (orquestração) ao EMR. A ideia: uma Step Function que
cria o cluster, adiciona o step e aguarda o término.

- Monte uma máquina de estados com os estados
  `createCluster → addStep → (sync) → terminateCluster`.
- **Desafio:** fazer funcionar **sem** solicitar o template pronto — montando a
  partir da documentação dos conectores de EMR no Step Functions.

## Limpeza

> Como o cluster é `--auto-terminate`, ele some ao fim dos steps. Mesmo assim:

```bash
aws emr terminate-clusters --cluster-ids "$CLUSTER_ID"
aws s3 rm "s3://$BUCKET/" --recursive
```

Veja também a seção "Limpeza" do `README.md`.
