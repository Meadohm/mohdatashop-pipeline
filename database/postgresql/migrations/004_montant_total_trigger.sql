-- ============================================================
-- Migration 004 : Vues, fonction stockée, trigger (N6)
-- Contexte : commandes.montant_total prévu depuis le README initial
--            mais jamais implémenté. Calcul manuel (JOIN+SUM) répété
--            à chaque affichage -> risque d'incohérence, duplication
--            de logique. Objectif : colonne stockée, mais maintenue
--            automatiquement (jamais mise à jour manuellement).
-- ============================================================

BEGIN;

-- 1. Ajout de la colonne montant_total (nullable au départ pour backfill)
ALTER TABLE commandes ADD COLUMN montant_total NUMERIC(12,2);

-- 2. Fonction stockée : calcule le total réel depuis lignes_commande
CREATE FUNCTION calculer_montant_commande(p_commande_id INT)
RETURNS NUMERIC AS $$
    SELECT COALESCE(SUM(quantite * prix_unitaire), 0)
    FROM lignes_commande
    WHERE commande_id = p_commande_id;
$$ LANGUAGE SQL;

-- 3. Backfill des commandes existantes
UPDATE commandes
SET montant_total = calculer_montant_commande(id);

-- 4. Fonction déclenchée par le trigger — recalcule à chaque changement
CREATE FUNCTION maj_montant_commande() RETURNS TRIGGER AS $$
BEGIN
    UPDATE commandes
    SET montant_total = calculer_montant_commande(COALESCE(NEW.commande_id, OLD.commande_id))
    WHERE id = COALESCE(NEW.commande_id, OLD.commande_id);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 5. Trigger : se déclenche sur toute modification des lignes de commande
CREATE TRIGGER trg_maj_montant
AFTER INSERT OR UPDATE OR DELETE ON lignes_commande
FOR EACH ROW EXECUTE FUNCTION maj_montant_commande();

-- 6. Contrainte NOT NULL une fois le backfill vérifié
ALTER TABLE commandes ALTER COLUMN montant_total SET NOT NULL;

-- 7. Vue pratique pour l'affichage des commandes
CREATE VIEW vue_commandes_detail AS
SELECT
    co.id AS commande_id,
    cl.nom AS client_nom,
    co.date_commande,
    co.statut,
    co.ville_livraison,
    co.montant_total
FROM commandes co
JOIN clients cl ON cl.id = co.client_id;

COMMIT;

-- ============================================================
-- Rollback manuel (si besoin de revenir en arrière) :
-- DROP VIEW IF EXISTS vue_commandes_detail;
-- DROP TRIGGER IF EXISTS trg_maj_montant ON lignes_commande;
-- DROP FUNCTION IF EXISTS maj_montant_commande();
-- DROP FUNCTION IF EXISTS calculer_montant_commande(INT);
-- ALTER TABLE commandes DROP COLUMN montant_total;
-- ============================================================
