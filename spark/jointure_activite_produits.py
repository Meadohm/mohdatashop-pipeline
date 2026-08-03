"""
MohdataShop — Jointure Spark entre logs d'activite et produits.
Illustre .join() et l'action .write() (persister un resultat, pas juste
l'afficher a l'ecran comme .show()).
"""

import os
from dotenv import load_dotenv
from pyspark.sql import SparkSession
from pyspark.sql.functions import desc, count

load_dotenv()

spark = SparkSession.builder \
    .appName("mohdatashop_spark_jointure") \
    .config("spark.jars.packages", "org.postgresql:postgresql:42.7.3") \
    .getOrCreate()

def lire_table(nom_table):
    return spark.read \
        .format("jdbc") \
        .option("url", f"jdbc:postgresql://{os.getenv('PG_HOST')}:{os.getenv('PG_PORT')}/{os.getenv('PG_DATABASE')}") \
        .option("dbtable", nom_table) \
        .option("user", os.getenv("PG_USER")) \
        .option("password", os.getenv("PG_PASSWORD")) \
        .option("driver", "org.postgresql.Driver") \
        .load()

logs = lire_table("stg_logs_activite")
produits = lire_table("produits")

# Transformation : ne garder que les consultations, compter par produit
consultations = (
    logs.filter(logs.action == "consultation_produit")
        .groupBy("metadata_produit_id")
        .agg(count("*").alias("nb_consultations"))
)

# Jointure : ajouter le nom/categorie du produit
# Cast metadata_produit_id (double, cf. flattening pandas) -> int pour joindre proprement
consultations_avec_nom = consultations.join(
    produits,
    consultations.metadata_produit_id.cast("int") == produits.id,
    how="left"
).select("id", "nom", "categorie_id", "nb_consultations") \
 .orderBy(desc("nb_consultations"))

print("--- Top consultations par produit ---")
consultations_avec_nom.show()

# Action : écriture du résultat en CSV
chemin_sortie = "spark/output/consultations_par_produit"
consultations_avec_nom.write.mode("overwrite").csv(chemin_sortie, header=True)
print(f"\nRésultat écrit dans : {chemin_sortie}")

spark.stop()