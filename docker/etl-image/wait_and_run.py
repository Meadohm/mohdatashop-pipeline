"""
Attend que PostgreSQL et MongoDB soient prêts (le premier démarrage prend
quelques secondes le temps d'exécuter les scripts d'init SQL/JS), puis
exécute le pipeline réel du projet (generate_fake_data + pipeline_rapport).

Nécessaire car `depends_on` dans docker-compose garantit seulement l'ordre
de DÉMARRAGE des conteneurs, pas que le service à l'intérieur soit déjà
prêt à accepter des connexions.
"""

import time

from db_connections import get_postgres_connection, get_mongo_database


def attendre_postgres(max_tentatives: int = 15, delai: int = 2) -> None:
    for tentative in range(1, max_tentatives + 1):
        try:
            conn = get_postgres_connection()
            conn.close()
            print("PostgreSQL prêt.")
            return
        except Exception:
            print(f"PostgreSQL pas encore prêt ({tentative}/{max_tentatives})...")
            time.sleep(delai)
    raise RuntimeError("PostgreSQL indisponible après plusieurs tentatives.")


def attendre_mongo(max_tentatives: int = 15, delai: int = 2) -> None:
    for tentative in range(1, max_tentatives + 1):
        try:
            db = get_mongo_database()
            db.command("ping")
            print("MongoDB prêt.")
            return
        except Exception:
            print(f"MongoDB pas encore prêt ({tentative}/{max_tentatives})...")
            time.sleep(delai)
    raise RuntimeError("MongoDB indisponible après plusieurs tentatives.")


if __name__ == "__main__":
    attendre_postgres()
    attendre_mongo()

    import generate_fake_data
    import pipeline_rapport

    generate_fake_data.generer_clients()
    generate_fake_data.generer_logs_activite()
    generate_fake_data.generer_avis()

    rapport = pipeline_rapport.construire_rapport()
    print(rapport.to_string(index=False))
