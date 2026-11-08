"""Trabalho final PDN, Parte 1: job PySpark rodado no EMR Serverless.

Leia os jogos do S3, filtre os do seu clube e calcule as 6 respostas do
entrega.json. Grave o resultado no S3 e copie os valores para o entrega.json.
"""
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("trabalho-final-pdn").getOrCreate()

# TODO: ler os jogos (S3), filtrar o clube, calcular e gravar as respostas.

spark.stop()
