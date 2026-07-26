# ERD — MohdataShop (PostgreSQL)

Diagramme entité-relation du schéma actuellement en base (MLD), 7 tables.
Source éditable : `erd_mohdatashop.mermaid`

![ERD MohdataShop](erd_mohdatashop.png)

<details>
<summary>Voir le code mermaid source</summary>

```mermaid
erDiagram
  CLIENTS ||--o{ COMMANDES : passe
  CATEGORIES ||--o{ PRODUITS : regroupe
  COMMANDES ||--o{ LIGNES_COMMANDE : contient
  PRODUITS ||--o{ LIGNES_COMMANDE : referme
  COMMANDES ||--o{ PAIEMENTS : genere
  COMMANDES ||--o{ LIVRAISONS : declenche

  CLIENTS {
    serial id PK
    varchar nom
    varchar ville
    varchar pays
    varchar telephone
    varchar moyen_paiement
    varchar email
    date date_inscription
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
    text description
  }
  COMMANDES {
    serial id PK
    int client_id FK
    date date_commande
    varchar statut
    varchar ville_livraison
    numeric montant_total
  }
  LIGNES_COMMANDE {
    serial id PK
    int commande_id FK
    int produit_id FK
    int quantite
    numeric prix_unitaire
  }
  PAIEMENTS {
    serial id PK
    int commande_id FK
    varchar methode
    numeric montant
    varchar statut
    timestamp date_paiement
  }
  LIVRAISONS {
    serial id PK
    int commande_id FK
    varchar ville
    varchar adresse
    varchar statut
    date date_livraison
  }
```

</details>

`clients.moyen_paiement` — décision N4 (migration 002) : préférence déclarative uniquement. Source de vérité transactionnelle : `paiements`.
