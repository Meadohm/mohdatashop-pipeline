"""
MohdataShop — Pratique des formats Parquet et JSON avec Spark (N6).
Complète le CSV deja pratique : lecture Postgres -> ecriture Parquet,
puis ecriture JSON -> relecture JSON, pour boucler read/write sur les
3 formats attendus par la roadmap (CSV, JSON, Parquet).
"""

import os
from dotenv import load_dotenv
from pyspark.sql import SparkSession

load_dotenv()

spark = SparkSession.builder \
    .appName("mohdatashop_spark_formats") \
    .config("spark.jars.packages", "org.postgresql:postgresql:42.7.3") \
    .getOrCreate()

df = spark.read \
    .format("jdbc") \
    .option("url", f"jdbc:postgresql://{os.getenv('PG_HOST')}:{os.getenv('PG_PORT')}/{os.getenv('PG_DATABASE')}") \
    .option("dbtable", "rapport_produits") \
    .option("user", os.getenv("PG_USER")) \
    .option("password", os.getenv("PG_PASSWORD")) \
    .option("driver", "org.postgresql.Driver") \
    .load()

# Ecriture Parquet
chemin_parquet = "spark/output/rapport_produits_parquet"
df.write.mode("overwrite").parquet(chemin_parquet)
print(f"Ecrit en Parquet : {chemin_parquet}")

# Ecriture JSON
chemin_json = "spark/output/rapport_produits_json"
df.write.mode("overwrite").json(chemin_json)
print(f"Ecrit en JSON : {chemin_json}")

# Relecture Parquet (verifie le round-trip)
df_parquet = spark.read.parquet(chemin_parquet)
print(f"\nRelu depuis Parquet : {df_parquet.count()} lignes")
df_parquet.show(3)

# Relecture JSON (verifie le round-trip)
df_json = spark.read.json(chemin_json)
print(f"\nRelu depuis JSON : {df_json.count()} lignes")
df_json.show(3)

spark.stop()