# MohdataShop — Pipeline Data End-to-End

Pipeline de données complet pour **MohdataShop**, boutique e-commerce fictive basée à Abidjan.
Projet fil conducteur de ma transition vers Data Engineer Junior - construit progressivement
au fil des modules : SQL => Bases de Données => Docker => Cloud => Pipelines & ETL.

---

## Contexte métier

| Dimension    | Détail                                          |
| ------------ | ----------------------------------------------- |
| Activité     | E-commerce - électronique, textile, alimentaire |
| Localisation | Abidjan, Côte d'Ivoire                          |
| Clients      | Zone UEMOA : CI, Sénégal, Mali, Burkina Faso    |
| Paiements    | Mobile Money (MTN, Orange, Wave) · Carte · Cash |
| Livraisons   | Abidjan + villes secondaires                    |

---

## Architecture cible

```
Sources              Transform                 Load              Visualise
-------              ---------                 ----              ---------
CSV / API    =>      Python + dbt      =>      PostgreSQL     => Power BI
PostgreSQL   =>      PySpark           =>      S3 / Redshift  => Dashboard
MongoDB      =>      Airflow DAG       =>      BigQuery       => Rapport
```

---

## Roadmap de construction

| Module                                  | Dossier           | Statut   |
| --------------------------------------- | ----------------- | -------- |
| SQL N1→N6                               | sql               | Terminé  |
| Bases de Données (PostgreSQL + MongoDB) | database          | En cours |
| Docker                                  | docker            | Terminé  |
| Cloud AWS/GCP                           | cloud             | -        |
| Pipelines & ETL (Airflow + dbt + Spark) | pipelines + spark | -        |
| Power BI                                | powerbi           | Terminé  |

---

## Schéma de base de données

**Implémenté en base (PostgreSQL) :**

```
clients          (id, nom, ville, pays, telephone, moyen_paiement ⚠️)
categories       (id, nom)
produits         (id, nom, categorie_id → categories.id, prix, stock)
commandes        (id, client_id → clients.id, date_commande, statut, ville_livraison)
lignes_commande  (id, commande_id → commandes.id, produit_id → produits.id, quantite, prix_unitaire)
```

⚠️ `clients.moyen_paiement` — à réévaluer. C'est un attribut figé par client (1 valeur), alors que le moyen de paiement réel peut varier par commande. La source de vérité transactionnelle sera la future table `paiements` (montant, statut, date par paiement). `clients.moyen_paiement` ne sera conservé que comme préférence déclarative optionnelle (ex : moyen par défaut pré-rempli en UI), pas comme donnée de paiement fiable — à trancher lors de la migration 002.

**Prévu (schéma cible, migrations à venir) :**

```
clients    + email, date_inscription
produits   + description
commandes  + montant_total (calculé depuis lignes_commande, ou via trigger)
paiements   (id, commande_id, methode, montant, statut, date_paiement)  -- remplace l'usage réel de moyen_paiement
livraisons  (id, commande_id, ville, adresse, statut, date_livraison)
```

Diagramme ERD (MLD) : [`database/postgresql/docs/erd_mohdatashop.md`](database/postgresql/docs/erd_mohdatashop.md)

Source éditable : `database/postgresql/docs/erd_mohdatashop.mermaid`

Migrations appliquées en base : voir `database/postgresql/migrations/`

- `001_normalize_categories.sql` appliquée (exécutée via `psql`) — extraction de `produits.categorie` (texte) vers table `categories` + FK
- `002_constraints_enum_index.sql` ⏳ écrite, pas encore appliquée — CHECK (prix/stock/quantité positifs), ENUM `statut_commande`, index sur les colonnes FK

Collections MongoDB :

```
logs_activite   { user_id, action, timestamp, metadata }
historique_prix { produit_id, prix, date_changement }
avis_clients    { client_id, produit_id, note, commentaire, date }
```

---

## Stack technique

| Couche           | Outils                                    |
| ---------------- | ----------------------------------------- |
| Langage          | Python 3.10+                              |
| Base de données  | PostgreSQL · MongoDB                      |
| Orchestration    | Apache Airflow 2.x                        |
| Transformation   | dbt · Pandas · PySpark                    |
| Cloud            | AWS (S3, Redshift, Glue) · GCP (BigQuery) |
| Conteneurisation | Docker · Docker Compose                   |
| Visualisation    | Power BI                                  |
| Versioning       | Git · GitHub                              |

---

## Structure du projet

```
mohdatashop-pipeline
├── data
│   ├── raw             # Données brutes (CSV, JSON)
│   └── processed       # Données transformées
├── sql
│   ├── schema          # Création des tables (schéma initial)
│   ├── queries         # Requêtes d'analyse
│   └── migrations      # Évolutions du schéma
├── database
│   ├── postgresql
│   │   ├── migrations  # Migrations SQL versionnées (001, 002, ...)
│   │   └── docs        # ERD et documentation du schéma
│   └── mongodb         # Config + scripts MongoDB
├── etl                 # Scripts Python ETL
├── pipelines
│   ├── airflow         # DAGs Airflow
│   └── dbt             # Modèles dbt
├── spark               # Scripts PySpark
├── cloud
│   ├── aws             # Configs AWS
│   └── gcp             # Configs GCP
├── docker              # Dockerfiles + docker-compose
└── powerbi             # Rapports .pbix
```

---

## Auteur

Mohamed — Ingénieur en transition vers le Data Engineering
Abidjan, Côte d'Ivoire · [GitHub](https://github.com/Meadohm)
