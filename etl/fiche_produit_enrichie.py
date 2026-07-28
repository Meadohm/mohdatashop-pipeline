"""
MohdataShop — N9 : premier croisement réel PostgreSQL + MongoDB.

Objectif : construire une "fiche produit" enrichie en combinant :
  - les données relationnelles du produit (PostgreSQL)
  - son historique de prix (MongoDB)
  - ses avis clients (MongoDB)

C'est le point clé de N9 : MongoDB ne peut pas faire de JOIN avec une
table PostgreSQL. Le croisement se fait ici, côté Python.
"""

from etl.db_connections import get_postgres_connection, get_mongo_database


def get_fiche_produit(produit_id: int) -> dict:
    # --- 1. Données relationnelles (PostgreSQL) ---
    pg_conn = get_postgres_connection()
    cur = pg_conn.cursor()
    cur.execute(
        """
        SELECT p.id, p.nom, p.prix, p.stock, c.nom AS categorie
        FROM produits p
        JOIN categories c ON c.id = p.categorie_id
        WHERE p.id = %s
        """,
        (produit_id,),
    )
    row = cur.fetchone()
    cur.close()
    pg_conn.close()

    if row is None:
        return {"erreur": f"Produit {produit_id} introuvable"}

    fiche = {
        "id": row[0],
        "nom": row[1],
        "prix_actuel": float(row[2]),
        "stock": row[3],
        "categorie": row[4],
    }

    # --- 2. Historique de prix (MongoDB) ---
    mongo_db = get_mongo_database()
    historique = list(
        mongo_db.historique_prix.find(
            {"produit_id": produit_id}, {"_id": 0}
        ).sort("date_changement", 1)
    )
    fiche["historique_prix"] = [
        {"prix": float(h["prix"].to_decimal()), "date": h["date_changement"].strftime("%Y-%m-%d")}
        for h in historique
    ]

    # --- 3. Avis clients (MongoDB) ---
    avis = list(
        mongo_db.avis_clients.find(
            {"produit_id": produit_id}, {"_id": 0}
        )
    )
    fiche["avis"] = avis
    fiche["note_moyenne"] = (
        round(sum(a["note"] for a in avis) / len(avis), 1) if avis else None
    )

    return fiche


if __name__ == "__main__":
    import json

    fiche = get_fiche_produit(1)
    print(json.dumps(fiche, indent=2, ensure_ascii=False, default=str))
