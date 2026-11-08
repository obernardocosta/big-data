# Trabalho final GDBD — Data Lake do meu clube

Integrantes: (nomes e matrículas)
Clube: (o seu)

## Arquitetura

(Desenho ou lista das 3 camadas — raw, clean, curated — com o caminho no S3, o
formato de cada uma e as tabelas do Glue Data Catalog. Diga qual ferramenta fez
cada transformação: Glue Job ou CTAS no Athena.)

## Decisões

(Para cada escolha importante, o porquê: formato, chave de partição, quando
usar Glue Job e quando usar CTAS. Relacione com o que vimos nas aulas.)

## Comparação CSV x Parquet

(Preencha a tabela com o "Data scanned" do Athena para a **mesma** consulta e
explique, com suas palavras, por que os números mudam.)

| Tabela | Formato | Particionada? | Data scanned |
|---|---|---|---|
| jogos_raw | CSV | não | |
| jogos_curated | Parquet | sim (`year`, `month`) | |

## Limpeza

(Liste o que você apagou ao final: buckets, databases, jobs, crawlers.)
