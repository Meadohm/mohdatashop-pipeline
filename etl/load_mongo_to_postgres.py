"""
MohdataShop — Loader Mongo -> PostgreSQL (préparation dbt).

Copie les collections MongoDB (avis_clients, logs_activite) vers des tables
PostgreSQL prefixees "stg_" (staging), pour que dbt puisse transformer les
3 sources du rapport en SQL pur, sans dependre de pymongo.

Idempotent (cf. N1) : chaque execution VIDE puis REMPLIT les tables stg_*
(TRUNCATE + append), jamais d'ajout cumulatif. On evite DROP+CREATE
("replace") car des vues dbt (stg_avis, stg_activite) dependent de ces
tables — Postgres refuse de dropper une table referencee par une vue.
"""

import pandas as pd
from sqlalchemy import text

from etl.db_connections import get_mongo_database, get_postgres_engine


def _recharger_table(df: pd.DataFrame, nom_table: str, engine) -> None:
    """Vide puis remplit une table, sans jamais la DROP (préserve les vues dépendantes)."""
    with engine.begin() as conn:
        conn.execute(text(f"TRUNCATE TABLE {nom_table}"))
    df.to_sql(nom_table, engine, if_exists="append", index=False)


def charger_avis_vers_postgres() -> int:
    """Copie mongo_db.avis_clients -> table PostgreSQL stg_avis_clients."""
    mongo_db = get_mongo_database()
    documents = list(mongo_db.avis_clients.find({}, {"_id": 0}))
    df = pd.DataFrame(documents)

    engine = get_postgres_engine()
    _recharger_table(df, "stg_avis_clients", engine)
    engine.dispose()

    print(f"{len(df)} avis copies vers PostgreSQL (stg_avis_clients).")
    return len(df)


def charger_logs_activite_vers_postgres() -> int:
    """Copie mongo_db.logs_activite -> table PostgreSQL stg_logs_activite."""
    mongo_db = get_mongo_database()
    documents = list(mongo_db.logs_activite.find({}, {"_id": 0}))
    df = pd.json_normalize(documents, sep="_")

    engine = get_postgres_engine()
    _recharger_table(df, "stg_logs_activite", engine)
    engine.dispose()

    print(f"{len(df)} logs copies vers PostgreSQL (stg_logs_activite).")
    return len(df)


if __name__ == "__main__":
    charger_avis_vers_postgres()
    charger_logs_activite_vers_postgres()