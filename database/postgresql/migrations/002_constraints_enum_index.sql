-- ============================================================
-- Migration 002 : Contraintes, ENUM, index (N4)
-- Contexte : aucune contrainte de validité sur les montants/quantités,
--            statut en texte libre, aucun index sur les colonnes FK
--            -> risque de données incohérentes + jointures lentes à l'échelle
-- ============================================================

BEGIN;

-- 1. Contraintes CHECK — validité des montants et quantités
ALTER TABLE produits
    ADD CONSTRAINT chk_produits_prix_positif CHECK (prix > 0),
    ADD CONSTRAINT chk_produits_stock_positif CHECK (stock >= 0);

ALTER TABLE lignes_commande
    ADD CONSTRAINT chk_lignes_quantite_positive CHECK (quantite > 0),
    ADD CONSTRAINT chk_lignes_prix_unitaire_positif CHECK (prix_unitaire > 0);

-- 2. ENUM pour commandes.statut — remplace le VARCHAR libre
CREATE TYPE statut_commande AS ENUM ('En attente', 'Livrée', 'Annulée');

-- Conversion de la colonne existante (les valeurs actuelles doivent matcher l'ENUM)
ALTER TABLE commandes
    ALTER COLUMN statut TYPE statut_commande
    USING statut::statut_commande;

-- 3. Index sur les colonnes FK (non indexées automatiquement par PostgreSQL)
CREATE INDEX idx_commandes_client_id ON commandes(client_id);
CREATE INDEX idx_produits_categorie_id ON produits(categorie_id);
CREATE INDEX idx_lignes_commande_commande_id ON lignes_commande(commande_id);
CREATE INDEX idx_lignes_commande_produit_id ON lignes_commande(produit_id);

COMMIT;

-- ============================================================
-- Décision moyen_paiement (N4) : conservé sur clients comme préférence
-- déclarative uniquement (pas de changement de schéma). La source de
-- vérité transactionnelle sera la future table `paiements` (migration
-- ultérieure), qui enregistrera le moyen réellement utilisé par commande.
-- ============================================================

-- ============================================================
-- Rollback manuel (si besoin de revenir en arrière) :
-- DROP INDEX IF EXISTS idx_commandes_client_id;
-- DROP INDEX IF EXISTS idx_produits_categorie_id;
-- DROP INDEX IF EXISTS idx_lignes_commande_commande_id;
-- DROP INDEX IF EXISTS idx_lignes_commande_produit_id;
-- ALTER TABLE commandes ALTER COLUMN statut TYPE VARCHAR(20) USING statut::text;
-- DROP TYPE IF EXISTS statut_commande;
-- ALTER TABLE lignes_commande DROP CONSTRAINT chk_lignes_quantite_positive;
-- ALTER TABLE lignes_commande DROP CONSTRAINT chk_lignes_prix_unitaire_positif;
-- ALTER TABLE produits DROP CONSTRAINT chk_produits_prix_positif;
-- ALTER TABLE produits DROP CONSTRAINT chk_produits_stock_positif;
-- ============================================================
