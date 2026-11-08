# Trabalho final — GDBD: Data Lake do meu clube

Vale **100% da nota** (veja o [`README` da avaliação](README.md)); os labs não valem
nota, são o treino para este trabalho. Pode ser feito
**individualmente ou em grupo de até 3 pessoas**; a nota do trabalho é a mesma
para todos do grupo.

- **Tempo estimado:** 4 a 6 horas.
- **Prazo:** 10 dias corridos após a última aula (o instrutor confirma a data na Aula 1).
- **Onde roda:** na **sua própria conta AWS**, região `us-east-1`.
- **Custo aproximado:** de centavos a ~US$ 1 se você limpar tudo no mesmo dia
  (Athena cobra por dado lido; os dados são pequenos). Veja
  [preço do Athena](https://aws.amazon.com/athena/pricing/).

## Por que este trabalho

Nos labs você fez cada peça isolada: catálogo, Athena, particionamento, Glue/Spark
e as três camadas do Data Lake. Aqui você monta **o caminho inteiro sozinho**, para
um recorte do dado só seu, e mede o ganho do que aprendeu (Parquet + partição)
em bytes lidos.

## O que você aprende

- Construir **Raw → Clean → Curated** de ponta a ponta, escolhendo a ferramenta
  (Glue Job ou CTAS no Athena) e justificando.
- Transformar o dado em outra **visão** (do jogo para o clube) em vez de só copiar.
- **Provar com números** por que formato colunar e particionamento reduzem custo.
- Responder perguntas de negócio com SQL, inclusive funções de janela.

## O seu clube

Cada grupo trabalha com **um clube** da Premier League 2024/25, definido pela
matrícula do **primeiro integrante** listado:

```bash
python3 tools/trabalho/trabalho.py clube 2024001
```

O script está em [`tools/trabalho`](https://github.com/obernardocosta/big-data/tree/main/tools/trabalho).
Os dados são os mesmos dos labs, do nosso
[repositório de dados](https://github.com/obernardocosta/data/tree/main/football)
(fonte original: [openfootball](https://github.com/openfootball/football.json)).

## O que fazer

1. **Raw.** Gere o CSV dos 380 jogos como no
   [Lab 01](https://github.com/obernardocosta/big-data/tree/main/disciplinas/gdbd/labs/lab-01-glue-catalog)
   e suba para o S3 (bucket seu). Catalogue a tabela no
   [Glue Data Catalog](https://console.aws.amazon.com/glue/) (Crawler **ou** DDL no
   [Athena](https://console.aws.amazon.com/athena/)).
2. **Clean.** Gere uma camada limpa: tipos corretos (data como `date`, gols como
   inteiro), sem jogos sem placar, nomes de coluna padronizados.
3. **Curated, a visão do clube.** Gere uma tabela **Parquet particionada por
   `year` e `month`** com **uma linha por jogo do seu clube**, na ótica dele
   (colunas sugeridas: `data`, `adversario`, `casa`, `gols_pro`, `gols_contra`,
   `pontos`). Atenção: o clube joga ora como mandante, ora como visitante.
   Catalogue a tabela.
4. **Responda 8 perguntas** com Athena sobre a camada curated (definições abaixo).
5. **Meça.** Rode a **mesma consulta** na camada raw (CSV) e na curated
   (Parquet particionado) e anote o *Data scanned* de cada uma.
6. **Documente** no `README.md` (arquitetura, decisões, comparação, limpeza).
7. **Limpe** os recursos e **valide** a entrega (abaixo).

> **Glue pode estar bloqueado em contas novas.** Se o Glue Job/Crawler der
> `Account is denied access`, use **CTAS no Athena** para Clean/Curated e **DDL**
> para as tabelas: o trabalho aceita as duas rotas. Nesse caso, explique no
> README por que escolheu CTAS.

## As 8 perguntas (campo `respostas` do `entrega.json`)

| Chave | Definição |
|---|---|
| `jogos` | Quantos jogos o clube disputou. |
| `pontos` | Pontos na temporada (vitória 3, empate 1, derrota 0). |
| `saldo_gols` | Gols marcados menos gols sofridos. |
| `pontos_casa` | Pontos conquistados como mandante. |
| `pontos_fora` | Pontos conquistados como visitante. |
| `maior_vitoria_saldo` | Maior diferença de gols em uma **vitória** (0 se nunca venceu). |
| `melhor_mes` | Mês (`AAAA-MM`) com mais pontos. Empate: o mês mais antigo. |
| `maior_sequencia_invicta` | Maior número de jogos seguidos **sem perder**, em ordem de data. Dica: [funções de janela](https://trino.io/docs/current/functions/window.html). |

## A medição (campos `bytes_csv` e `bytes_parquet_particionado`)

Escolha uma consulta que dê o **mesmo resultado** nas duas tabelas, por exemplo
"soma dos pontos do clube em dezembro de 2024". Na tabela CSV você precisa
calcular os pontos e filtrar o clube; na Parquet, filtre pelas partições
`year`/`month`. Leia o *Data scanned* na aba **Query stats** do Athena, ou:

```bash
aws athena get-query-execution --query-execution-id <ID> \
  --query 'QueryExecution.Statistics.DataScannedInBytes'
```

Guarde os IDs das consultas em `athena_query_ids` (mínimo 3). No README, explique
**com suas palavras** por que os números mudam (leitura colunar, partition pruning).

## O que entregar

Uma pasta (zip ou repositório) com os arquivos do
[`trabalho-modelo/`](https://github.com/obernardocosta/big-data/tree/main/disciplinas/gdbd/avaliacao/trabalho-modelo)
preenchidos:

```
entrega.json    # identificação, respostas, IDs do Athena e bytes medidos
README.md       # seções: Arquitetura, Decisões, Comparação CSV x Parquet, Limpeza
consultas.sql   # todas as consultas/DDLs, comentadas (Parquet, partitioned_by, OVER)
```

**Antes de entregar**, rode a autoconferência (ela checa formato e estrutura, mas
**não** diz se as respostas estão certas):

```bash
python3 tools/trabalho/trabalho.py validar minha-entrega --disciplina gdbd
```

## Como será corrigido (10,0 pontos = 100% da nota)

| Parte | Pontos | Como |
|---|---|---|
| Respostas corretas | 4,0 | automático (8 × 0,5) |
| Estrutura do README e do `consultas.sql` | 1,4 | automático |
| Evidências do Athena (IDs; Parquet lê menos que CSV) | 0,6 | automático |
| Pipeline em 3 camadas coerente e reprodutível | 1,0 | instrutor |
| Decisões justificadas (Glue Job × CTAS, formato, chave de partição) | 1,0 | instrutor |
| Comparação CSV × Parquet explicada com o conceito | 1,0 | instrutor |
| Consultas que reproduzem as respostas + limpeza feita | 1,0 | instrutor |

## Limpeza

Apague ao final: buckets criados (esvazie antes), tabelas e databases do Glue,
jobs/crawlers e resultados do Athena. Liste o que apagou no README.

## Encontrou um problema neste trabalho?

[Abra uma issue](https://github.com/obernardocosta/big-data/issues/new?template=problema-no-lab.yml).
