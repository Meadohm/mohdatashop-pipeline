"""
Connexions réutilisables PostgreSQL + MongoDB pour MohdataShop.
Credentials chargés depuis .env (jamais codés en dur).
"""

import os
import psycopg2
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()


def get_postgres_connection():
    """Ouvre une connexion PostgreSQL (psycopg2) — pour INSERT/UPDATE/DDL."""
    return psycopg2.connect(
        host=os.getenv("PG_HOST"),
        port=os.getenv("PG_PORT"),
        dbname=os.getenv("PG_DATABASE"),
        user=os.getenv("PG_USER"),
        password=os.getenv("PG_PASSWORD"),
    )


def get_postgres_engine():
    """Ouvre un engine SQLAlchemy — requis par pandas.read_sql (évite le warning).

    Utilise URL.create() plutôt qu'une f-string : gère automatiquement
    l'encodage des caractères spéciaux (@, :, /...) dans le mot de passe,
    qui casseraient sinon le format de l'URL de connexion.
    """
    url = URL.create(
        drivername="postgresql+psycopg2",
        username=os.getenv("PG_USER"),
        password=os.getenv("PG_PASSWORD"),
        host=os.getenv("PG_HOST"),
        port=int(os.getenv("PG_PORT")),
        database=os.getenv("PG_DATABASE"),
    )
    return create_engine(url)


def get_mongo_database():
    """Ouvre une connexion MongoDB et retourne la base mohdatashop."""
    client = MongoClient(os.getenv("MONGO_URI"))
    return client[os.getenv("MONGO_DATABASE")]
