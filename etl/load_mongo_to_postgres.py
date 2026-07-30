"""
MohdataShop — Loader Mongo -> PostgreSQL (préparation dbt).

Copie les collections MongoDB (avis_clients, logs_activite) vers des tables
PostgreSQL prefixees "stg_" (staging), pour que dbt puisse transformer les
3 sources du rapport en SQL pur, sans dependre de pymongo.

Idempotent (cf. N1) : chaque execution REMPLACE le contenu des tables stg_*
(if_exists="replace"), jamais d'ajout cumulatif. Relancer 10 fois produit
le meme etat final.
"""

import pandas as pd

from etl.db_connections import get_mongo_database, get_postgres_engine


def charger_avis_vers_postgres() -> int:
    """Copie mongo_db.avis_clients -> table PostgreSQL stg_avis_clients."""
    mongo_db = get_mongo_database()
    documents = list(mongo_db.avis_clients.find({}, {"_id": 0}))
    df = pd.DataFrame(documents)

    engine = get_postgres_engine()
    df.to_sql("stg_avis_clients", engine, if_exists="replace", index=False)
    engine.dispose()

    print(f"{len(df)} avis copies vers PostgreSQL (stg_avis_clients).")
    return len(df)


def charger_logs_activite_vers_postgres() -> int:
    """Copie mongo_db.logs_activite -> table PostgreSQL stg_logs_activite.

    Le champ "metadata" est imbrique et variable selon l'action
    (consultation_produit a un produit_id, achat a un montant, etc.).
    json_normalize l'aplatit en colonnes plates (metadata_produit_id,
    metadata_montant, ...) pour obtenir une table SQL exploitable par dbt.
    """
    mongo_db = get_mongo_database()
    documents = list(mongo_db.logs_activite.find({}, {"_id": 0}))
    df = pd.json_normalize(documents, sep="_")

    engine = get_postgres_engine()
    df.to_sql("stg_logs_activite", engine, if_exists="replace", index=False)
    engine.dispose()

    print(f"{len(df)} logs copies vers PostgreSQL (stg_logs_activite).")
    return len(df)


if __name__ == "__main__":
    charger_avis_vers_postgres()
    charger_logs_activite_vers_postgres()