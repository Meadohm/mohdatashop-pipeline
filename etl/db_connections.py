"""
Connexions réutilisables PostgreSQL + MongoDB pour MohdataShop.
Credentials chargés depuis .env (jamais codés en dur).
"""

import os
import psycopg2
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()


def get_postgres_connection():
    """Ouvre une connexion PostgreSQL (psycopg2)."""
    return psycopg2.connect(
        host=os.getenv("PG_HOST"),
        port=os.getenv("PG_PORT"),
        dbname=os.getenv("PG_DATABASE"),
        user=os.getenv("PG_USER"),
        password=os.getenv("PG_PASSWORD"),
    )


def get_mongo_database():
    """Ouvre une connexion MongoDB et retourne la base mohdatashop."""
    client = MongoClient(os.getenv("MONGO_URI"))
    return client[os.getenv("MONGO_DATABASE")]
