"""
MohdataShop — N10 : pipeline complet.

Extract  : PostgreSQL (commandes, ventes) + MongoDB (avis, logs)
Transform: Pandas (jointures, agrégations)
Load     : rapport CSV dans data/processed/

Referme la roadmap Bases de Données (N1 -> N10).
"""

import os
import pandas as pd

from etl.db_connections import get_postgres_engine, get_mongo_database
from pathlib import Path

def extraire_ventes_postgres() -> pd.DataFrame:
    """Extrait les ventes par produit depuis PostgreSQL."""
    engine = get_postgres_engine()
    query = """
        SELECT
            p.id AS produit_id,
            p.nom AS produit,
            c.nom AS categorie,
            SUM(lc.quantite) AS quantite_vendue,
            SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires
        FROM lignes_commande lc
        JOIN produits p ON p.id = lc.produit_id
        JOIN categories c ON c.id = p.categorie_id
        GROUP BY p.id, p.nom, c.nom
        ORDER BY chiffre_affaires DESC
    """
    df = pd.read_sql(query, engine)
    engine.dispose()
    return df


def extraire_avis_mongo() -> pd.DataFrame:
    """Extrait la note moyenne par produit depuis MongoDB."""
    mongo_db = get_mongo_database()
    pipeline = [
        {"$group": {"_id": "$produit_id", "note_moyenne": {"$avg": "$note"}, "nb_avis": {"$sum": 1}}}
    ]
    resultats = list(mongo_db.avis_clients.aggregate(pipeline))
    df = pd.DataFrame(resultats).rename(columns={"_id": "produit_id"})
    return df


def extraire_activite_mongo() -> pd.DataFrame:
    """Compte les actions logs_activite par produit consulté (Faker-générées, cf. N10)."""
    mongo_db = get_mongo_database()
    pipeline = [
        {"$match": {"action": "consultation_produit"}},
        {"$group": {"_id": "$metadata.produit_id", "nb_consultations": {"$sum": 1}}},
    ]
    resultats = list(mongo_db.logs_activite.aggregate(pipeline))
    df = pd.DataFrame(resultats).rename(columns={"_id": "produit_id"})
    return df


def construire_rapport() -> pd.DataFrame:
    """Assemble les 3 sources en un rapport unique (le croisement final du pipeline)."""
    ventes = extraire_ventes_postgres()
    avis = extraire_avis_mongo()
    activite = extraire_activite_mongo()

    rapport = ventes.merge(avis, on="produit_id", how="left")
    rapport = rapport.merge(activite, on="produit_id", how="left")

    rapport["note_moyenne"] = rapport["note_moyenne"].round(1)
    rapport["nb_avis"] = rapport["nb_avis"].fillna(0).astype(int)
    rapport["nb_consultations"] = rapport["nb_consultations"].fillna(0).astype(int)

    return rapport.sort_values("chiffre_affaires", ascending=False)


def sauvegarder_rapport(rapport: pd.DataFrame, chemin_sortie: Path) -> None:
    """Écrit le rapport en CSV de façon atomique : écrit dans un .tmp puis renomme.
    Évite un fichier corrompu/partiel si le process crash pendant l'écriture."""
    chemin_sortie.parent.mkdir(parents=True, exist_ok=True)
    chemin_tmp = chemin_sortie.with_suffix(".tmp.csv")
    rapport.to_csv(chemin_tmp, index=False)
    os.replace(chemin_tmp, chemin_sortie)  # opération atomique du système de fichiers


if __name__ == "__main__":
    rapport = construire_rapport()

    print(rapport.to_string(index=False))

    # Chemin ancré sur la position du fichier, pas sur le cwd —
    # fonctionne identiquement en lancement direct et sous Airflow.
    BASE_DIR = Path(__file__).resolve().parent.parent
    chemin_sortie = BASE_DIR / "data" / "processed" / "rapport_produits.csv"
    sauvegarder_rapport(rapport, chemin_sortie)
    print(f"\nRapport exporté : {chemin_sortie}")
