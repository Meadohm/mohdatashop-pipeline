// ============================================================
// MohdataShop — Initialisation MongoDB (N7)
// Exécution : mongosh mohdatashop init_collections.js
// ============================================================

use("mohdatashop");

// ------------------------------------------------------------
// Collection 1 : logs_activite
// Traçabilité des actions utilisateurs (structure metadata variable)
// ------------------------------------------------------------
db.createCollection("logs_activite", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["user_id", "action", "timestamp"],
      properties: {
        user_id: { bsonType: "int", description: "reference clients.id (PostgreSQL)" },
        action: { bsonType: "string" },
        timestamp: { bsonType: "date" },
        metadata: { bsonType: "object", description: "structure libre selon l'action" }
      }
    }
  }
});

db.logs_activite.insertMany([
  {
    user_id: 1,
    action: "connexion",
    timestamp: new Date("2026-07-20T08:15:00Z"),
    metadata: { device: "mobile", ville: "Abidjan" }
  },
  {
    user_id: 1,
    action: "consultation_produit",
    timestamp: new Date("2026-07-20T08:17:00Z"),
    metadata: { produit_id: 1, device: "mobile" }
  },
  {
    user_id: 3,
    action: "achat",
    timestamp: new Date("2026-07-20T09:02:00Z"),
    metadata: { commande_id: 9, montant: 15000, moyen_paiement: "MTN" }
  }
]);

// ------------------------------------------------------------
// Collection 2 : historique_prix
// Un document par changement de prix (write-heavy, lecture rare)
// ------------------------------------------------------------
db.createCollection("historique_prix", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["produit_id", "prix", "date_changement"],
      properties: {
        produit_id: { bsonType: "int", description: "reference produits.id (PostgreSQL)" },
        prix: { bsonType: "decimal" },
        date_changement: { bsonType: "date" }
      }
    }
  }
});

db.historique_prix.insertMany([
  { produit_id: 1, prix: NumberDecimal("90000.00"), date_changement: new Date("2026-01-15") },
  { produit_id: 1, prix: NumberDecimal("85000.00"), date_changement: new Date("2026-06-01") },
  { produit_id: 4, prix: NumberDecimal("17000.00"), date_changement: new Date("2026-02-10") },
  { produit_id: 4, prix: NumberDecimal("15000.00"), date_changement: new Date("2026-05-20") }
]);

// ------------------------------------------------------------
// Collection 3 : avis_clients
// Structure simple, mais évolutive sans migration
// ------------------------------------------------------------
db.createCollection("avis_clients", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["client_id", "produit_id", "note"],
      properties: {
        client_id: { bsonType: "int", description: "reference clients.id (PostgreSQL)" },
        produit_id: { bsonType: "int", description: "reference produits.id (PostgreSQL)" },
        note: { bsonType: "int", minimum: 1, maximum: 5 },
        commentaire: { bsonType: "string" },
        date: { bsonType: "date" }
      }
    }
  }
});

db.avis_clients.insertMany([
  {
    client_id: 1,
    produit_id: 1,
    note: 5,
    commentaire: "Très satisfait, livraison rapide à Abidjan.",
    date: new Date("2026-06-05")
  },
  {
    client_id: 3,
    produit_id: 7,
    note: 4,
    commentaire: "Bon produit, conforme à la description.",
    date: new Date("2026-06-25")
  }
]);

// ------------------------------------------------------------
// Index — équivalent des index FK vus en N4 côté PostgreSQL
// ------------------------------------------------------------
db.logs_activite.createIndex({ user_id: 1 });
db.logs_activite.createIndex({ timestamp: -1 });
db.historique_prix.createIndex({ produit_id: 1 });
db.avis_clients.createIndex({ produit_id: 1 });

print("Collections créées : logs_activite, historique_prix, avis_clients");
