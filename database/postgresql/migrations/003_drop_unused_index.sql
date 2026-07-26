-- ============================================================
-- Migration 003 : suppression d'un index créé hors migration
-- Contexte : idx_commandes_client_statut existait en base sans trace
--            dans les migrations versionnées (001, 002). Vérification
--            via pg_stat_user_indexes : idx_scan = 0, idx_tup_read = 0
--            -> jamais utilisé par aucune requête depuis sa création.
--            Un index inutile ralentit les écritures (INSERT/UPDATE)
--            sur `commandes` sans aucun bénéfice en lecture.
-- ============================================================

BEGIN;

DROP INDEX IF EXISTS idx_commandes_client_statut;

COMMIT;

-- ============================================================
-- Rollback manuel (si besoin de le recréer) :
-- CREATE INDEX idx_commandes_client_statut ON commandes(client_id, statut);
-- ============================================================
