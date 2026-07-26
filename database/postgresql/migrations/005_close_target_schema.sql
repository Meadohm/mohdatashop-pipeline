-- ============================================================
-- Migration 005 : Clôture du schéma cible relationnel
-- Contexte : email, date_inscription, description, paiements et
--            livraisons figuraient dans le README comme "prévus"
--            depuis le tout début du projet, sans jamais être
--            rattachés à un niveau précis de la roadmap -> risque
--            de rester "prévus" indéfiniment. Traités ici en bloc
--            avant de basculer sur MongoDB (N7).
-- ============================================================

BEGIN;

-- 1. clients : ajout email + date_inscription
-- Nullable car aucune donnée existante pour ces colonnes (pas de
-- valeur fiable à backfiller) ; à rendre NOT NULL plus tard si un
-- flux d'inscription réel impose ces champs.
ALTER TABLE clients ADD COLUMN email VARCHAR(150) UNIQUE;
ALTER TABLE clients ADD COLUMN date_inscription DATE DEFAULT CURRENT_DATE;

-- 2. produits : ajout description
ALTER TABLE produits ADD COLUMN description TEXT;

-- 3. Table paiements — source de vérité transactionnelle (cf. décision N4
--    sur clients.moyen_paiement, qui reste une préférence déclarative)
CREATE TYPE statut_paiement AS ENUM ('En attente', 'Réussi', 'Échoué', 'Remboursé');

CREATE TABLE paiements (
    id             SERIAL PRIMARY KEY,
    commande_id    INT NOT NULL REFERENCES commandes(id),
    methode        VARCHAR(20) NOT NULL, -- MTN, Orange, Wave, Carte, Cash (même convention que clients.moyen_paiement)
    montant        NUMERIC(12,2) NOT NULL CHECK (montant > 0),
    statut         statut_paiement NOT NULL DEFAULT 'En attente',
    date_paiement  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_paiements_commande_id ON paiements(commande_id);

-- 4. Table livraisons
CREATE TABLE livraisons (
    id              SERIAL PRIMARY KEY,
    commande_id     INT NOT NULL REFERENCES commandes(id),
    ville           VARCHAR(50) NOT NULL,
    adresse         VARCHAR(200),
    statut          VARCHAR(20) NOT NULL DEFAULT 'En préparation', -- En préparation, Expédiée, Livrée, Retournée
    date_livraison  DATE
);

CREATE INDEX idx_livraisons_commande_id ON livraisons(commande_id);

COMMIT;

-- ============================================================
-- Rollback manuel (si besoin de revenir en arrière) :
-- DROP TABLE IF EXISTS livraisons;
-- DROP TABLE IF EXISTS paiements;
-- DROP TYPE IF EXISTS statut_paiement;
-- ALTER TABLE produits DROP COLUMN description;
-- ALTER TABLE clients DROP COLUMN date_inscription;
-- ALTER TABLE clients DROP COLUMN email;
-- ============================================================
