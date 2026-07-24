# ERD — MohdataShop (PostgreSQL)

Diagramme entité-relation du schéma actuellement en base (MLD).
Source éditable : `erd_mohdatashop.mermaid`

```mermaid
erDiagram
  CLIENTS ||--o{ COMMANDES : passe
  CATEGORIES ||--o{ PRODUITS : regroupe
  COMMANDES ||--o{ LIGNES_COMMANDE : contient
  PRODUITS ||--o{ LIGNES_COMMANDE : referme

  CLIENTS {
    serial id PK
    varchar nom
    varchar ville
    varchar pays
    varchar telephone
    varchar moyen_paiement
  }
  CATEGORIES {
    serial id PK
    varchar nom
  }
  PRODUITS {
    serial id PK
    varchar nom
    int categorie_id FK
    numeric prix
    int stock
  }
  COMMANDES {
    serial id PK
    int client_id FK
    date date_commande
    varchar statut
    varchar ville_livraison
  }
  LIGNES_COMMANDE {
    serial id PK
    int commande_id FK
    int produit_id FK
    int quantite
    numeric prix_unitaire
  }
```

⚠️ `clients.moyen_paiement` — à réévaluer (cf. `README.md`, section Schéma de base de données).
