// ============================================================
// MohdataShop — Exemples CRUD MongoDB (N7)
// ============================================================

use("mohdatashop");

// ------------------------------------------------------------
// CREATE
// ------------------------------------------------------------

// Ajouter un nouveau log d'activité
db.logs_activite.insertOne({
  user_id: 5,
  action: "ajout_panier",
  timestamp: new Date(),
  metadata: { produit_id: 3, quantite: 2 }
});

// ------------------------------------------------------------
// READ
// ------------------------------------------------------------

// Tous les logs d'un utilisateur, triés du plus récent au plus ancien
db.logs_activite.find({ user_id: 1 }).sort({ timestamp: -1 });

// Historique de prix d'un produit (équivalent d'un ORDER BY en SQL)
db.historique_prix.find({ produit_id: 1 }).sort({ date_changement: 1 });

// Avis avec une note >= 4 (équivalent WHERE note >= 4)
db.avis_clients.find({ note: { $gte: 4 } });

// Projection : ne récupérer que certains champs (équivalent SELECT partiel)
db.avis_clients.find(
  { produit_id: 1 },
  { commentaire: 1, note: 1, _id: 0 }
);

// ------------------------------------------------------------
// UPDATE
// ------------------------------------------------------------

// Corriger un commentaire existant
db.avis_clients.updateOne(
  { client_id: 1, produit_id: 1 },
  { $set: { commentaire: "Très satisfait, livraison rapide et emballage soigné." } }
);

// Ajouter un nouveau champ à tous les documents d'une collection
// (impossible aussi simplement en SQL sans migration ALTER TABLE)
db.avis_clients.updateMany(
  {},
  { $set: { verified_purchase: true } }
);

// ------------------------------------------------------------
// DELETE
// ------------------------------------------------------------

// Supprimer les logs de plus de 90 jours (purge, cas fréquent en prod)
db.logs_activite.deleteMany({
  timestamp: { $lt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000) }
});

// ------------------------------------------------------------
// Agrégation — équivalent GROUP BY
// ------------------------------------------------------------

// Note moyenne par produit (équivalent SQL : GROUP BY produit_id, AVG(note))
db.avis_clients.aggregate([
  { $group: { _id: "$produit_id", note_moyenne: { $avg: "$note" }, nb_avis: { $sum: 1 } } },
  { $sort: { note_moyenne: -1 } }
]);
