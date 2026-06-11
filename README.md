# MohdataShop — Pipeline Data End-to-End

Pipeline de données complet pour **MohdataShop**, boutique e-commerce fictive basée à Abidjan.
Projet fil conducteur de ma transition vers Data Engineer Junior - construit progressivement
au fil des modules : SQL → Bases de Données → Docker → Cloud → Pipelines & ETL.

---

## Contexte métier

| Dimension      | Détail |
|----------------|--------|
| Activité       | E-commerce - électronique, textile, alimentaire |
| Localisation   | Abidjan, Côte d'Ivoire |
| Clients        | Zone UEMOA : CI, Sénégal, Mali, Burkina Faso |
| Paiements      | Mobile Money (MTN, Orange, Wave) · Carte · Cash |
| Livraisons     | Abidjan + villes secondaires |

---

## Architecture cible

```
Sources              Transform                 Load              Visualise
-------              ---------                 ----              ---------
CSV / API    =>       Python + dbt      =>       PostgreSQL   =>   Power BI
PostgreSQL   =>       PySpark           =>       S3 / Redshift =>  Dashboard
MongoDB      =>       Airflow DAG       =>       BigQuery     =>   Rapport
```

---

## Roadmap de construction

| Module | Dossier | Statut |
|--------|---------|--------|
| SQL N1→N6 | sql | - |
| Bases de Données (PostgreSQL + MongoDB) | database | - |
| Docker | docker | - |
| Cloud AWS/GCP | cloud | - |
| Pipelines & ETL (Airflow + dbt + Spark) | pipelines + spark | - |
| Power BI | powerbi | - |

---

## Schéma de base de données

```
clients      (id, nom, email, telephone, ville, pays, date_inscription)
categories   (id, nom)
produits     (id, nom, categorie_id, prix, stock, description)
commandes    (id, client_id, date_commande, statut, montant_total)
lignes_cmde  (id, commande_id, produit_id, quantite, prix_unitaire)
paiements    (id, commande_id, methode, montant, statut, date_paiement)
livraisons   (id, commande_id, ville, adresse, statut, date_livraison)
```

Collections MongoDB :
```
logs_activite   { user_id, action, timestamp, metadata }
historique_prix { produit_id, prix, date_changement }
avis_clients    { client_id, produit_id, note, commentaire, date }
```

---

## Stack technique

| Couche | Outils |
|--------|--------|
| Langage | Python 3.10+ |
| Base de données | PostgreSQL · MongoDB |
| Orchestration | Apache Airflow 2.x |
| Transformation | dbt · Pandas · PySpark |
| Cloud | AWS (S3, Redshift, Glue) · GCP (BigQuery) |
| Conteneurisation | Docker · Docker Compose |
| Visualisation | Power BI |
| Versioning | Git · GitHub |

---

## Structure du projet

```
mohdatashop-pipeline
├── data
│   ├── raw           # Données brutes (CSV, JSON)
│   └── processed     # Données transformées
├── sql
│   ├── schema        # Création des tables
│   ├── queries       # Requêtes d'analyse
│   └── migrations    # Évolutions du schéma
├── database
│   ├── postgresql    # Config + scripts PostgreSQL
│   └── mongodb       # Config + scripts MongoDB
├── etl               # Scripts Python ETL
├── pipelines
│   ├── airflow       # DAGs Airflow
│   └── dbt           # Modèles dbt
├── spark             # Scripts PySpark
├── cloud
│   ├── aws           # Configs AWS
│   └── gcp           # Configs GCP
├── docker            # Dockerfiles + docker-compose
└── powerbi           # Rapports .pbix
```

---

## Auteur

Mohamed — Ingénieur en transition vers le Data Engineering
Abidjan, Côte d'Ivoire · [GitHub](https://github.com/Meadohm)
