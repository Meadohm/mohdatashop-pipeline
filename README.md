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
| --------------------------------------- | ------------------| ---------|
| SQL N1→N6                               | sql               | Terminé  |
| Bases de Données (PostgreSQL + MongoDB) | database          | Terminé  |
| Docker                                  | docker            | Terminé  |
| Cloud AWS/GCP                           | cloud             | -        |
| Pipelines & ETL (Airflow + dbt + Spark) | pipelines + spark | -        |
| Power BI                                | powerbi           | -        |

---

## Schéma de base de données

**Implémenté en base (PostgreSQL) — schéma relationnel clos :**

```
clients          (id, nom, ville, pays, telephone, moyen_paiement, email, date_inscription)
categories       (id, nom)
produits         (id, nom, categorie_id → categories.id, prix, stock, description)
commandes        (id, client_id → clients.id, date_commande, statut, ville_livraison, montant_total)
lignes_commande  (id, commande_id → commandes.id, produit_id → produits.id, quantite, prix_unitaire)
paiements        (id, commande_id → commandes.id, methode, montant, statut, date_paiement)
livraisons       (id, commande_id → commandes.id, ville, adresse, statut, date_livraison)
```

`clients.moyen_paiement` — décision prise en N4 (migration 002) : conservé comme préférence déclarative uniquement, pas comme donnée de paiement fiable. La source de vérité transactionnelle est la table `paiements` (méthode réellement utilisée par commande, montant, statut, date).

`commandes.montant_total` — implémenté en N6 (migration 004) : maintenu automatiquement par trigger (`trg_maj_montant`), jamais mis à jour manuellement. Voir fonction `calculer_montant_commande()`.

`clients.email`, `clients.date_inscription`, `produits.description`, `paiements`, `livraisons` — implémentés en migration 005, clôturant le schéma relationnel cible défini depuis le début du projet.

Diagramme ERD (MLD) : [`database/postgresql/docs/erd_mohdatashop.md`](database/postgresql/docs/erd_mohdatashop.md) — 7 tables, synchronisé avec migration 005

Source éditable : `database/postgresql/docs/erd_mohdatashop.mermaid`

Migrations appliquées en base : voir `database/postgresql/migrations/`

- `001_normalize_categories.sql` appliquée (exécutée via `psql`) — extraction de `produits.categorie` (texte) vers table `categories` + FK
- `002_constraints_enum_index.sql` appliquée (exécutée via `psql`) — CHECK (prix/stock/quantité positifs), ENUM `statut_commande`, index sur les colonnes FK
- `003_drop_unused_index.sql` appliquée (exécutée via `psql`) — suppression de `idx_commandes_client_statut`, index présent en base sans trace dans les migrations versionnées, `idx_scan = 0` confirmé via `pg_stat_user_indexes` avant suppression
- `004_montant_total_trigger.sql` appliquée (exécutée via `psql`) — ajout `commandes.montant_total`, fonction `calculer_montant_commande()`, trigger `trg_maj_montant` (recalcul automatique), vue `vue_commandes_detail`
- `005_close_target_schema.sql` appliquée (exécutée via `psql`) — `clients.email`/`date_inscription`, `produits.description`, tables `paiements` et `livraisons` (ENUM `statut_paiement`, index sur FK)

Objets SQL disponibles :

| Type | Nom | Rôle |
|---|---|---|
| Fonction | `calculer_montant_commande(id)` | Calcule le total réel d'une commande depuis `lignes_commande` |
| Trigger | `trg_maj_montant` | Recalcule `montant_total` à chaque INSERT/UPDATE/DELETE sur `lignes_commande` |
| Vue | `vue_commandes_detail` | Jointure clients + commandes prête à l'emploi |

Transactions et isolation (N5) : [`sql/queries/test_transaction_stock.sql`](sql/queries/test_transaction_stock.sql) — script de démonstration de l'isolation `READ COMMITTED` + rôle du `CHECK` (migration 002) comme filet de sécurité, testé en conditions réelles avec deux sessions `psql` concurrentes

Collections MongoDB — implémentées en N7 (`database/mongodb/`) :

```
logs_activite   { user_id, action, timestamp, metadata }
historique_prix { produit_id, prix, date_changement }
avis_clients    { client_id, produit_id, note, commentaire, date, verified_purchase ⚠️ }
```

⚠️ `avis_clients.verified_purchase` — champ absent du schéma initial, ajouté a posteriori via `db.avis_clients.updateMany({}, {$set: {verified_purchase: true}})` dans `exemples_crud.js`, pour illustrer concrètement un avantage du NoSQL : ajout d'un champ à tous les documents existants sans migration `ALTER TABLE`. Volontaire, pas une dérive.

- `init_collections.js` — création des 3 collections (validation de schéma souple `$jsonSchema`), données d'exemple, index
- `exemples_crud.js` — CRUD + agrégation commentés, comparés aux équivalents SQL, incluant l'ajout dynamique de `verified_purchase`

Synthèse SQL vs NoSQL (N8) : [`database/docs/sql_vs_nosql.md`](database/docs/sql_vs_nosql.md) — critère de décision et répartition PostgreSQL/MongoDB appliquée à MohdataShop, vérifiées en conditions réelles via `mongosh` interactif

**Connexion Python → PostgreSQL + MongoDB (N9)** — `etl/` :

- `db_connections.py` — connexions réutilisables (`psycopg2` + `pymongo`), credentials via `.env` (jamais commité)
- `fiche_produit_enrichie.py` — premier croisement réel des deux SGBD : fiche produit combinant données relationnelles (PostgreSQL) + historique de prix et avis (MongoDB), assemblés côté Python

⚠️ Copier `.env.example` en `.env` avant utilisation, remplir les credentials réels. `.env` doit être dans `.gitignore`.

**Pipeline complet (N10)** — `etl/`, referme la roadmap Bases de Données :

- `generate_fake_data.py` — génère **300 clients** (PostgreSQL) + **8000 `logs_activite`** (MongoDB) + **avis pour ~15% des clients** (MongoDB, distribution de notes réaliste pondérée positive) via **Faker** (locale `fr_FR`). Remplace le volume trop faible des données statiques (8 clients réutilisés en boucle, 2 avis fixes) par un jeu de données réaliste. Utile aussi pour observer un vrai `Index Scan` côté PostgreSQL avec du volume (cf. N4, limite atteinte faute de volume à l'époque)
- `pipeline_rapport.py` — pipeline final : extrait ventes (PostgreSQL, via `get_postgres_engine()` SQLAlchemy) + avis + activité (MongoDB), croise avec Pandas, exporte `data/processed/rapport_produits.csv`

⚠️ `faker` et `sqlalchemy` (déjà présent) requis dans `requirements.txt`

---

## Docker testé de bout en bout

Conteneurise l'ensemble : PostgreSQL + MongoDB + conteneur ETL exécutant le pipeline réel (N9/N10) — pas de script factice, les vrais scripts du projet.

Validé en conditions réelles : init automatique du schéma PostgreSQL (7 tables + 5 migrations) et des 3 collections MongoDB sur volumes vierges, pipeline complet exécuté avec succès dans le conteneur (`mohdata-etl exited with code 0`), données vérifiées visuellement via DBeaver (PostgreSQL) et MongoDB Compass (MongoDB, 48 documents `avis_clients` confirmés).

```
docker
├── docker-compose.yml     # 3 services : postgres, mongodb, etl
├── .env.docker.example    # template credentials (copier en .env.docker, jamais commité)
└── etl-image              # infrastructure de build UNIQUEMENT (pas de logique métier)
    ├── Dockerfile         # build le conteneur ETL depuis etl/ (racine du repo)
    ├── requirements.txt   # dépendances slim du conteneur (pas le requirements.txt complet du repo)
    └── wait_and_run.py    # attend que PostgreSQL/MongoDB soient prêts, puis lance le pipeline
```

⚠️ `etl-image/` (dans `docker/`) ≠ `etl/` (racine du repo) : le premier ne contient que l'infrastructure de conteneurisation, le second le vrai code Python métier (N9/N10). Renommé explicitement pour éviter la confusion entre les deux.

**Initialisation automatique au premier démarrage** (dossier de volume vide) :
- PostgreSQL : `sql/schema/00_schema_mohdatashop.sql` + les 5 migrations, dans l'ordre
- MongoDB : `database/mongodb/init_collections.js` (3 collections + données de départ)

**Utilisation :**

```bash
cd docker
cp .env.docker.example .env.docker
# éditer .env.docker, remplir POSTGRES_PASSWORD/PG_PASSWORD (mêmes valeurs)

docker compose up --build
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
│   ├── mongodb         # Config + scripts MongoDB
│   └── docs            # Documentation transversale (SQL vs NoSQL, etc.)
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
