"""
MohdataShop — Premier script PySpark.
Lit rapport_produits (table PostgreSQL, alimentée par dbt) via JDBC,
applique transformations + action pour illustrer lazy evaluation.
"""

import os
from dotenv import load_dotenv
from pyspark.sql import SparkSession

load_dotenv()

spark = SparkSession.builder \
    .appName("mohdatashop_spark") \
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

electronique = df.filter(df.categorie == "Electronique")
trie = electronique.orderBy(df.chiffre_affaires.desc())

trie.show()

spark.stop()