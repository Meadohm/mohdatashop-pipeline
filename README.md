# MohdataShop — Pipeline Data End-to-End

Pipeline de données complet pour **MohdataShop**, boutique e-commerce fictive basée à Abidjan.
Projet fil conducteur de ma transition vers Data Engineer Junior - construit progressivement
au fil des modules : SQL => Bases de Données => Docker => Pipelines & ETL => Cloud => Power BI.

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
PostgreSQL   =>      Python (loader)   =>      PostgreSQL   =>   Power BI
MongoDB      =>      dbt (SQL)         =>      (entrepôt    =>   Dashboard
             =>      PySpark                    unique)          Rapport

Orchestration : Apache Airflow (Docker)
```

Architecture actuelle (Pipelines & ETL) : PostgreSQL et MongoDB alimentent un **entrepôt PostgreSQL unique**. Un loader Python (`etl/load_mongo_to_postgres.py`) copie les collections Mongo pertinentes en tables staging PostgreSQL ; **dbt** transforme ensuite tout en SQL (staging → mart). **PySpark** vient compléter l'analyse (agrégations, jointures, écriture multi-formats) sur les mêmes données, en manipulation directe. Airflow orchestre le pipeline dbt. Il n'y a plus de fichier CSV généré par le pipeline courant — la source de vérité est la table PostgreSQL `rapport_produits` (voir section dbt).

---

## Roadmap de construction

| Module                                   | Dossier             | Statut   |
| -----------------------------------------| ------------------- | -------- |
| SQL N1→N6                                | sql                 | Terminé  |
| Bases de Données (PostgreSQL + MongoDB)  | database            | Terminé  |
| Docker                                   | docker              | Terminé  |
| Pipelines & ETL — Airflow                | pipelines/airflow   | Terminé  |
| Pipelines & ETL — dbt                    | pipelines/dbt       | Terminé  |
| Pipelines & ETL — Spark                  | spark               | Terminé  |
| Pipelines & ETL — Streaming (notions)    | -                   | Terminé  |
| Cloud AWS/GCP                            | cloud               | -        |
| Power BI                                 | powerbi             | -        |

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
avis_clients    { client_id, produit_id, note, commentaire, date, verified_purchase ⚠️}
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

- `generate_fake_data.py` — génère **300 clients** (PostgreSQL) + **8000 `logs_activite`** (MongoDB) + **avis pour ~15% des clients** (MongoDB, distribution de notes réaliste pondérée positive) via **Faker** (locale `fr_FR`). Script de **seed**, jamais exécuté par un DAG planifié (non idempotent par nature, cf. section Airflow).
- `pipeline_rapport.py` — pipeline pandas historique : extrait ventes (PostgreSQL) + avis + activité (MongoDB), croise avec Pandas, exporte un CSV. **Conservé comme trace de l'approche initiale (avant migration dbt) mais n'est plus le pipeline exécuté en production** — remplacé par l'approche dbt (voir section dédiée). Le fichier `data/processed/rapport_produits.csv` qu'il produit est un artefact figé, pas régénéré automatiquement.

⚠️ `faker` et `sqlalchemy` (déjà présent) requis dans `requirements.txt`

---

## Docker testé de bout en bout

Conteneurise l'ensemble : PostgreSQL + MongoDB + conteneur ETL (seed/démo) + conteneur Airflow (orchestration).

Validé en conditions réelles : init automatique du schéma PostgreSQL (7 tables + 5 migrations) et des 3 collections MongoDB sur volumes vierges, pipeline exécuté avec succès (`mohdata-etl exited with code 0`), données vérifiées visuellement via DBeaver (PostgreSQL) et MongoDB Compass (MongoDB, 48 documents `avis_clients` confirmés). Stabilité confirmée : 3 conteneurs (postgres, mongodb, airflow) tournant en continu plusieurs jours sans redémarrage, DAG re-déclenché manuellement avec succès après ajout des modules dbt et Spark.

```
docker
├── docker-compose.yml     # 4 services : postgres, mongodb, etl, airflow
├── .env.docker.example    # template credentials (copier en .env.docker, jamais commité)
├── etl-image              # infrastructure de build du conteneur seed/démo
│   ├── Dockerfile
│   ├── requirements.txt   # dépendances slim (pas le requirements.txt complet du repo)
│   └── wait_and_run.py    # attend Postgres/Mongo prêts, puis lance generate_fake_data + pipeline_rapport
└── airflow-image          # infrastructure de build du conteneur d'orchestration
    └── Dockerfile         # apache/airflow + dépendances etl + dbt-postgres (contraintes officielles Airflow)
```

⚠️ `etl-image/` (dans `docker/`) ≠ `etl/` (racine du repo) : le premier ne contient que l'infrastructure de conteneurisation, le second le vrai code Python métier.

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

## Pipelines & ETL — Orchestration Airflow

Airflow orchestre le pipeline de bout en bout dans un conteneur dédié (mode `standalone`, `SequentialExecutor` — suffisant pour ce volume de tasks, pas fait pour la production).

DAG unique `mohdatashop_rapport` (`pipelines/airflow/dags/mohdatashop_rapport_dag.py`), TaskFlow API, `@daily`, 2 retries :

```
charger_avis      ─┐
charger_activite  ─┼─→ dbt_run
```

- `charger_avis` / `charger_activite` (tasks parallèles) : appellent `etl/load_mongo_to_postgres.py`, copient les collections Mongo `avis_clients`/`logs_activite` vers les tables PostgreSQL `stg_avis_clients`/`stg_logs_activite`. Idempotent par **TRUNCATE + append** (pas de `DROP TABLE` : des vues dbt dépendent de ces tables, Postgres refuse de dropper une table référencée).
- `dbt_run` (`BashOperator`) : lance `dbt run` dans le conteneur, credentials via `pipelines/dbt/profiles_docker.yml` (monté dans le conteneur, `host: postgres` — nom de service Docker, pas `localhost`).

Testé en conditions réelles : les 3 tasks passent au vert, `rapport_produits` (table PostgreSQL, matérialisée par dbt) recalculée à chaque run avec des données à jour.

⚠️ `etl/generate_fake_data.py` n'est **jamais** appelé par le DAG — un script de seed régénéré chaque jour casserait l'idempotence du rapport (nouvelles données aléatoires à chaque run).

---

## Pipelines & ETL — dbt

Transforme les données déjà en PostgreSQL en SQL pur (approche **ELT** : extraction/chargement minimal via Python, toute la transformation en SQL versionné, testé, documenté).

```
pipelines/dbt/mohdatashop_dbt
├── models
│   ├── staging
│   │   ├── sources.yml          # déclare les tables/vues sources (5 : produits, categories,
│   │   │                        #   lignes_commande, stg_avis_clients, stg_logs_activite)
│   │   ├── stg_ventes.sql       # vue — ventes par produit (jointure produits/categories/lignes_commande)
│   │   ├── stg_avis.sql         # vue — note moyenne + nb avis par produit
│   │   ├── stg_activite.sql     # vue — nb consultations par produit
│   │   └── schema.yml           # tests not_null / unique sur produit_id (3 modèles)
│   └── marts
│       ├── rapport_produits.sql # TABLE (materialized='table') — mart final, 3× ref(),
│       │                        #   reproduit le rapport historique pandas, en SQL
│       └── schema.yml           # tests sur produit_id + chiffre_affaires
├── dbt_project.yml
└── profiles_docker.yml          # profil de connexion pour le conteneur Airflow (non versionné
                                 #   dans .dbt/ local — profil local séparé, voir ci-dessous)
```

`rapport_produits` (mart, matérialisé en **table**) remplace le CSV pandas comme sortie finale du pipeline. 9 tests dbt (`not_null`, `unique`), tous passants.

⚠️ `metadata_produit_id` (issu de l'aplatissement JSON des logs Mongo) est en `double precision` côté staging (mélange de `NaN`/valeurs numériques côté pandas) — casté en `::int` dans `stg_activite.sql` pour la jointure.

**Utilisation locale (hors Docker)** :

```bash
pip install dbt-postgres --break-system-packages
cd pipelines/dbt/mohdatashop_dbt
dbt debug     # valide la connexion (profil local dans ~/.dbt/profiles.yml, host: localhost)
dbt run
dbt test
```

**Documentation interactive** (lineage graph, colonnes, tests) :

```bash
dbt docs generate
dbt docs serve --port 8081   # 8080 pris par Airflow
```

---

## Pipelines & ETL — PySpark

Manipulation directe des données du projet avec PySpark (DataFrames, transformations/actions, lazy evaluation), en local, via connexion JDBC à PostgreSQL. Pas encore intégré à Airflow — usage manuel/exploratoire à ce stade, comme dbt avant son intégration au DAG.

```
spark
├── premiere_analyse.py              # lecture rapport_produits (JDBC), filter + orderBy + show
├── analyse_activite.py              # lecture stg_logs_activite, groupBy + count (par ville, par device)
├── jointure_activite_produits.py    # join stg_logs_activite x produits, ecriture CSV (action write)
├── formats_json_parquet.py          # ecriture + relecture Parquet et JSON depuis rapport_produits
└── .gitignore                       # exclut output/ (resultats generes, non versionnes)
```

Concepts pratiqués sur données réelles du projet :
- **DataFrame** (colonnes typées, pas de RDD brut) via lecture JDBC PostgreSQL
- **Transformation vs action** : `filter`/`orderBy`/`groupBy`/`join` ne s'exécutent qu'au moment d'un `.show()`/`.count()`/`.write()`
- **Lazy evaluation** : le plan complet est optimisé avant exécution, à l'appel de l'action
- **Formats** : lecture/écriture CSV, JSON et Parquet (colonnaire, binaire, compressé — format standard pour le stockage intermédiaire en Data Engineering)

⚠️ Nécessite Java (JDK 17+) en plus de `pyspark` — Spark tourne sur la JVM. Le driver JDBC PostgreSQL (`org.postgresql:postgresql:42.7.3`) est téléchargé automatiquement au premier lancement via `spark.jars.packages` (connexion internet requise une fois, puis mis en cache localement).

**Utilisation** :

```bash
pip install pyspark --break-system-packages
brew install openjdk@17
# suivre les instructions Homebrew affichées pour lier le PATH et le symlink système

python spark/premiere_analyse.py
```

Credentials PostgreSQL chargés depuis `.env` (comme `etl/db_connections.py`), jamais en dur dans les scripts.

Streaming (Spark Streaming, Kafka) : notions posées (producer/topic/consumer, micro-batching), non implémentées — les données du projet sont générées par un script de seed ponctuel (`generate_fake_data.py`), pas un flux d'événements réels, ce qui rendrait une infrastructure Kafka disproportionnée par rapport à la valeur pédagogique apportée.

---

## Stack technique

| Couche           | Outils                                    |
| ---------------- | ------------------------------------------|
| Langage          | Python 3.10+                              |
| Base de données  | PostgreSQL · MongoDB                      |
| Orchestration    | Apache Airflow 2.9 (Docker)               |
| Transformation   | dbt · PySpark · Pandas (historique)       |
| Cloud            | AWS (S3, Redshift, Glue) · GCP (BigQuery) |
| Conteneurisation | Docker · Docker Compose                   |
| Visualisation    | Power BI                                  |
| Versioning       | Git · GitHub                              |

---

## Structure du projet

```
mohdatashop-pipeline
├── data
│   ├── raw                  # Données brutes (CSV, JSON)
│   └── processed            # rapport_produits.csv — artefact historique (pipeline pandas), non régénéré
├── sql
│   ├── schema               # Création des tables (schéma initial)
│   ├── queries              # Requêtes d'analyse
│   └── migrations           # Évolutions du schéma
├── database
│   ├── postgresql
│   │   ├── migrations       # Migrations SQL versionnées (001, 002, ...)
│   │   └── docs             # ERD et documentation du schéma
│   ├── mongodb              # Config + scripts MongoDB
│   └── docs                 # Documentation transversale (SQL vs NoSQL, etc.)
├── etl                      # Scripts Python : connexions, seed, loader Mongo->Postgres
├── pipelines
│   ├── airflow
│   │   └── dags             # DAG mohdatashop_rapport
│   └── dbt
│       └── mohdatashop_dbt  # projet dbt (models/staging, models/marts)
├── spark                    # Scripts PySpark (lecture/transformation/ecriture, formats multiples)
├── cloud
│   ├── aws                  # Configs AWS
│   └── gcp                  # Configs GCP
├── docker                   # Dockerfiles (etl-image, airflow-image) + docker-compose
└── powerbi                  # Rapports .pbix
```

---

## Auteur

Mohamed — Ingénieur en transition vers le Data Engineering
Abidjan, Côte d'Ivoire · [GitHub](https://github.com/Meadohm)
