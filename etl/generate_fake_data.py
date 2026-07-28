"""
MohdataShop — N10 : génération de données réalistes avec Faker.

Idée validée en session précédente : remplacer les données statiques
(8 clients, logs et avis codés en dur depuis N7) par un volume réaliste.
Trois volets :
  1. Générer de nouveaux clients Faker (PostgreSQL) — corrige le manque
     de réalisme signalé : 500 logs sur 8 clients réutilisés en boucle
     n'était pas représentatif d'un usage réel.
  2. Générer un volume de logs_activite conséquent (MongoDB), répartis
     sur l'ensemble des clients (les 8 initiaux + les nouveaux Faker).
  3. Générer des avis pour un échantillon réaliste de clients (MongoDB) —
     seule une minorité de clients laisse un avis dans la réalité, pas 100%.

Utile aussi pour observer enfin un vrai "Index Scan" côté PostgreSQL
(cf. N4, où le volume de test était trop faible pour que l'index soit
choisi par le planificateur).

Ce script COMPLÈTE les données existantes, ne les écrase pas : les 8
clients/10 produits initiaux restent la référence "métier" du projet.
"""

import random

from faker import Faker
from etl.db_connections import get_postgres_connection, get_mongo_database

fake = Faker("fr_FR")  # locale française, cohérent avec le contexte UEMOA

NB_NOUVEAUX_CLIENTS = 300
NB_LOGS = 8000

ACTIONS = ["connexion", "consultation_produit", "ajout_panier", "achat", "deconnexion"]
DEVICES = ["mobile", "desktop", "tablette"]
VILLES_PAYS_UEMOA = [
    ("Abidjan", "Côte d'Ivoire"),
    ("Bouaké", "Côte d'Ivoire"),
    ("San Pedro", "Côte d'Ivoire"),
    ("Dakar", "Sénégal"),
    ("Thiès", "Sénégal"),
    ("Bamako", "Mali"),
    ("Ouagadougou", "Burkina Faso"),
]
MOYENS_PAIEMENT = ["MTN", "Orange", "Wave", "Carte", "Cash"]

# Distribution réaliste des notes e-commerce : majorité positive, minorité de critiques
NOTES_PONDEREES = [1, 2, 3, 4, 4, 5, 5, 5, 5]

COMMENTAIRES_POSITIFS = [
    "Très satisfait, produit conforme à la description.",
    "Livraison rapide, je recommande.",
    "Bon rapport qualité-prix.",
    "Exactement ce que j'attendais.",
    "Service impeccable, à refaire.",
]
COMMENTAIRES_NEUTRES = [
    "Correct sans plus.",
    "Produit convenable, livraison un peu longue.",
    "Conforme mais l'emballage était abîmé.",
]
COMMENTAIRES_NEGATIFS = [
    "Déçu par la qualité, ne correspond pas à mes attentes.",
    "Livraison en retard, produit endommagé à réception.",
    "Ne recommande pas ce produit.",
]


def generer_avis(taux_clients_avec_avis: float = 0.15) -> None:
    """Génère des avis réalistes pour un échantillon de clients (MongoDB).

    Dans la réalité, seule une minorité de clients laisse un avis (ici 15%,
    typique du taux de conversion avis/achat en e-commerce) — générer un avis
    pour chaque client serait irréaliste.
    """
    pg_conn = get_postgres_connection()
    cur = pg_conn.cursor()
    cur.execute("SELECT id FROM clients")
    client_ids = [row[0] for row in cur.fetchall()]
    cur.execute("SELECT id FROM produits")
    produit_ids = [row[0] for row in cur.fetchall()]
    cur.close()
    pg_conn.close()

    nb_avis = int(len(client_ids) * taux_clients_avec_avis)
    clients_avec_avis = random.sample(client_ids, nb_avis)

    mongo_db = get_mongo_database()
    avis = []

    for client_id in clients_avec_avis:
        note = random.choice(NOTES_PONDEREES)
        if note >= 4:
            commentaire = random.choice(COMMENTAIRES_POSITIFS)
        elif note == 3:
            commentaire = random.choice(COMMENTAIRES_NEUTRES)
        else:
            commentaire = random.choice(COMMENTAIRES_NEGATIFS)

        avis.append({
            "client_id": client_id,
            "produit_id": random.choice(produit_ids),
            "note": note,
            "commentaire": commentaire,
            "date": fake.date_time_between(start_date="-90d", end_date="now"),
            "verified_purchase": random.random() < 0.8,  # 80% d'achats vérifiés, cohérent avec N7
        })

    mongo_db.avis_clients.insert_many(avis)
    print(f"{nb_avis} avis générés (Faker) pour {nb_avis}/{len(client_ids)} clients ({taux_clients_avec_avis:.0%}).")


def generer_clients(nb_clients: int = NB_NOUVEAUX_CLIENTS) -> None:
    """Génère nb_clients clients réalistes supplémentaires dans PostgreSQL."""
    conn = get_postgres_connection()
    cur = conn.cursor()

    clients = []
    for _ in range(nb_clients):
        ville, pays = random.choice(VILLES_PAYS_UEMOA)
        clients.append((
            fake.name(),
            ville,
            pays,
            fake.phone_number()[:20],
            random.choice(MOYENS_PAIEMENT),
            fake.unique.email(),
            fake.date_between(start_date="-2y", end_date="today"),
        ))

    cur.executemany(
        """
        INSERT INTO clients (nom, ville, pays, telephone, moyen_paiement, email, date_inscription)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        """,
        clients,
    )
    conn.commit()
    cur.close()
    conn.close()
    print(f"{nb_clients} clients générés (Faker) et insérés dans PostgreSQL.")


def generer_logs_activite(nb_logs: int = NB_LOGS) -> None:
    """Génère nb_logs documents logs_activite réalistes dans MongoDB,
    répartis sur TOUS les clients (initiaux + Faker)."""
    pg_conn = get_postgres_connection()
    cur = pg_conn.cursor()
    cur.execute("SELECT id FROM clients")
    client_ids = [row[0] for row in cur.fetchall()]
    cur.execute("SELECT id FROM produits")
    produit_ids = [row[0] for row in cur.fetchall()]
    cur.close()
    pg_conn.close()

    mongo_db = get_mongo_database()
    logs = []

    for _ in range(nb_logs):
        action = random.choice(ACTIONS)
        timestamp = fake.date_time_between(start_date="-90d", end_date="now")
        ville, _ = random.choice(VILLES_PAYS_UEMOA)

        metadata = {"device": random.choice(DEVICES), "ville": ville}
        if action == "consultation_produit":
            metadata["produit_id"] = random.choice(produit_ids)
        elif action == "ajout_panier":
            metadata["produit_id"] = random.choice(produit_ids)
            metadata["quantite"] = random.randint(1, 5)
        elif action == "achat":
            metadata["montant"] = round(random.uniform(2000, 100000), 2)
            metadata["moyen_paiement"] = random.choice(MOYENS_PAIEMENT)

        logs.append({
            "user_id": random.choice(client_ids),
            "action": action,
            "timestamp": timestamp,
            "metadata": metadata,
        })

    mongo_db.logs_activite.insert_many(logs)
    print(f"{nb_logs} logs_activite générés (Faker) et insérés, répartis sur {len(client_ids)} clients.")


if __name__ == "__main__":
    generer_clients()
    generer_logs_activite()
    generer_avis()
