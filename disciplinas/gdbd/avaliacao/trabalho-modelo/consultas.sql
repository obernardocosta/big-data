-- Trabalho final GDBD: todas as consultas e DDLs usados, na ordem em que rodaram.
-- Comente cada bloco com a pergunta que ele responde (ex.: "-- pontos_casa").

-- 1) Camada curated: Parquet particionado (CTAS)
-- CREATE TABLE futebol.jogos_curated
-- WITH (format = 'PARQUET', partitioned_by = ARRAY['year', 'month'], external_location = 's3://SEU-BUCKET/curated/jogos/')
-- AS SELECT ... ;

-- 2) Respostas (uma consulta por chave de respostas.* do entrega.json)
-- 3) Sequência invicta: use funções de janela (OVER ...)
