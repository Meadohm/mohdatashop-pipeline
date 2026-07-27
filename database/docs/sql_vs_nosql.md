# SQL vs NoSQL — MohdataShop (N8)

## Comparaison structurelle

| Critère | SQL (PostgreSQL) | NoSQL (MongoDB) |
|---|---|---|
| Schéma | Fixe, défini à l'avance | Flexible, variable par document |
| Relations | Natives (FK, JOIN) | Absentes — gérées côté applicatif |
| Cohérence (ACID) | Forte par défaut | Plus faible par défaut, configurable |
| Montée en charge | Verticale principalement | Horizontale (sharding) plus naturelle |
| Requêtage complexe | JOIN, GROUP BY, sous-requêtes | Agrégations ($group, $lookup), plus verbeux |
| Écriture massive | Correcte mais contrainte | Optimisée pour le volume |

## Critère de décision

Question à se poser pour chaque nouvelle donnée à modéliser :
**la structure est-elle stable et fortement relationnelle ?**

- Oui -> PostgreSQL
- Non (structure variable, ou écriture prime sur relation) -> MongoDB

## Répartition MohdataShop (approche hybride / polyglot persistence)

| Donnée | SGBD | Justification |
|---|---|---|
| clients, produits, commandes, lignes_commande | PostgreSQL | Relations FK fortes, intégrité (CHECK), transactions ACID (cf. N4/N5) |
| paiements, livraisons | PostgreSQL | Liées à commandes par FK, cohérence transactionnelle nécessaire |
| logs_activite | MongoDB | `metadata` de forme variable selon l'action |
| historique_prix | MongoDB | Écriture fréquente, lecture rare, pas de relation complexe |
| avis_clients | MongoDB | Structure évolutive sans migration (cf. ajout `verified_purchase` en N7) |

## Principe retenu pour la suite du projet

Ne pas choisir un camp par défaut. Appliquer le critère de décision à chaque nouvelle donnée
rencontrée en N9/N10 (pipeline Python) avant de décider où elle va.
