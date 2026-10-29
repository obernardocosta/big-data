---
layout: section
routeAlias: aula-1
---

# Aula 1 — Amazon EMR Serverless

PDN · terça · 18h30–22h · ~3h30

<!--
Aula 1 da PDN. Origem: _fonte/pdn_2025_aula1 e pdn_2025_parte1 (slides 2-10).
Refino pedagógico: abertura com objetivos + agenda cronometrada; teoria curta
antes da prática; fechamento com "o que você leva". Ver .kiro/steering/didatica.md.

CONDUÇÃO: é a 1ª aula da PDN — avise que começa 18h30 em ponto (tolerância 10
min). A partir da Aula 2, 30 min iniciais para dúvidas.
-->

---

## O que você vai levar desta aula

Ao final, você será capaz de:

- Explicar **por que** o EMR Serverless existe e o que ele muda frente ao EMR tradicional.
- Desenhar a relação **Application → Job** e o papel da **RuntimeRole por job**.
- Justificar **quando** usar Serverless vs cluster, com argumento de **preço e TCO**.
- Submeter um **job PySpark** (iniciado hoje, aprofundado no sábado).

<!--
Leia os objetivos em voz alta: ancoram a aula. No fim, retomamos cada um.
-->

---

## Roteiro de hoje (3h30)

| Tempo | Bloco |
|---|---|
| 0:00–0:10 | Abertura e combinados |
| 0:10–0:35 | De onde viemos: o peso do EMR tradicional |
| 0:35–1:20 | EMR Serverless: Application, Job, RuntimeRole |
| 1:20–1:45 | Preço e TCO — quando vale |
| 1:45–2:00 | **Intervalo** |
| 2:00–3:30 | **Lab 01** — primeiro job PySpark (início guiado) |

<!-- Combine o timebox com a turma. Respeitar o relógio é parte da aula. -->

---
layout: center
---

## De onde viemos

Na GDBD, subir um **cluster EMR** significava decidir: tipo de cluster, VPC,
roles do cluster, quantas instâncias, quando ligar e desligar.

### Pergunta para abrir: o que desse trabalho é sobre o *dado*, e o que é só
### *infraestrutura*?

<!--
Deixe a turma responder 30s. A resposta — "quase tudo é infra" — motiva o
serverless. Não entregue de imediato.
-->

---

## O problema

O cluster tradicional cobra **enquanto está de pé**, mesmo ocioso, e exige
operação contínua (dimensionar, VPC, resiliência).

Para cargas **intermitentes** — vários times, jobs isolados, picos — isso é caro
e pesado.

### E se a abstração fosse **o job**, não a máquina?

---

## O que é o Amazon EMR Serverless

Opção **serverless** do EMR (lançada em **2022**). Em uma frase:

> Você entrega o **job**; a AWS aloca os recursos, roda e cobra só por isso.

- Abstração por **recurso** (vCPU e RAM), não por instâncias.
- **Sem VPC** obrigatória, sem ligar/desligar cluster.
- Permissão no nível do **job** (RuntimeRole).

---

## Application → Job

Você cria uma **Application** (ambiente Spark ou Hive). Ela sobe capacidade
**sob demanda** quando um job chega e a libera depois.

```mermaid {scale: 0.7}
flowchart LR
  A[EMR Serverless Application<br/>Spark ou Hive] -->|start-job-run| J1[Job 1<br/>+ RuntimeRole 1]
  A -->|start-job-run| J2[Job 2<br/>+ RuntimeRole 2]
  J1 --> S3[(S3)]
  J2 --> S3
```

Sem liga/desliga: você **submete jobs** à Application.

---

## A sacada: RuntimeRole por job

Dois jobs com necessidades diferentes:

- **job 1**: lê a tabela A, escreve na B.
- **job 2**: lê B e C, escreve na D.

| | EMR tradicional | EMR Serverless |
|---|---|---|
| Onde fica a permissão | no **cluster** (todos os jobs juntos) | em cada **job** (RuntimeRole) |
| Resultado | permissão "grande demais" | **menor privilégio** real |

<!--
Este é o ponto conceitual mais forte da aula. Conecte com segurança: menos
blast radius se um job for comprometido.
-->

---

## Preço e TCO — quando vale

- **Preço**: paga vCPU-hora + GB-hora **durante o job**. Ocioso → ~zero.
- **TCO**: sem operar cluster/VPC/escala, cai o custo de **time**, não só de AWS.

**Use Serverless quando:** cargas intermitentes/variáveis, muitos jobs isolados,
times que não querem manter cluster.
**Prefira cluster quando:** uso contínuo e intenso, com reaproveitamento constante.

<div class="text-sm opacity-70 mt-4">
Leitura: EMR Serverless Review — medium.com/@bernardo.costa/emr-serverless-review-51b659f2ca54
</div>

---
layout: center
---

## Intervalo — 15 min

<!-- Retome pontualmente. Na volta: mão na massa no Lab 01. -->

---
layout: section
---

# Prática

Lab 01 — primeiro job PySpark (início hoje)

---

## Lab 01 — começamos agora, terminamos no sábado

Hoje: **pré-requisitos + primeiro job**. O aprofundamento (dependências Python,
Hive) fica para a Aula 3 (sábado, dia de labs).

- Criar a **Application** e a **RuntimeRole**.
- Submeter um **job PySpark** e ver o estado chegar a `SUCCESS`.

**Timebox hoje:** ~1h. **Ponto de parada seguro:** job submetido e em execução.

Instruções versionadas: `labs/lab-01-emr-serverless/` · rode o `dry-run.sh` antes.

<!--
Deixe claro o que é "pronto para hoje". Quem não terminar, retoma no sábado nos
30 min iniciais. Ninguém fica preso aqui.
-->

---

## O que você leva de hoje

- EMR Serverless troca **gerenciar cluster** por **submeter jobs**.
- **RuntimeRole por job** = menor privilégio de verdade.
- A decisão Serverless vs cluster é de **custo e TCO**, não de moda.
- Seu primeiro job PySpark já está rodando.

### Próxima aula (quinta): **Machine Learning na AWS com SageMaker**.

<!-- Retome os 4 objetivos do início e confirme um a um com a turma. -->
