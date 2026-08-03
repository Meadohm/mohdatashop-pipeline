"""
MohdataShop — Analyse des logs d'activité avec PySpark.
Volume plus consequent (8500 lignes) que rapport_produits, pertinent pour
illustrer groupBy — transformation combinee a une action d'agregation.
"""

import os
from dotenv import load_dotenv
from pyspark.sql import SparkSession
from pyspark.sql.functions import desc

load_dotenv()

spark = SparkSession.builder \
    .appName("mohdatashop_spark_activite") \
    .config("spark.jars.packages", "org.postgresql:postgresql:42.7.3") \
    .getOrCreate()

df = spark.read \
    .format("jdbc") \
    .option("url", f"jdbc:postgresql://{os.getenv('PG_HOST')}:{os.getenv('PG_PORT')}/{os.getenv('PG_DATABASE')}") \
    .option("dbtable", "stg_logs_activite") \
    .option("user", os.getenv("PG_USER")) \
    .option("password", os.getenv("PG_PASSWORD")) \
    .option("driver", "org.postgresql.Driver") \
    .load()

print(f"Nombre total de logs : {df.count()}")  # action — declenche le premier calcul reel

# Transformation 1 : nb d'evenements par ville (exclut les lignes sans ville)
par_ville = (
    df.filter(df.metadata_ville.isNotNull())
      .groupBy("metadata_ville")
      .count()
      .orderBy(desc("count"))
)

print("\n--- Activite par ville ---")
par_ville.show()

# Transformation 2 : nb d'evenements par device
par_device = (
    df.filter(df.metadata_device.isNotNull())
      .groupBy("metadata_device")
      .count()
      .orderBy(desc("count"))
)

print("\n--- Activite par device ---")
par_device.show()

spark.stop()