-- ============================================================
-- Test N5 : isolation transactionnelle sur produits.stock
-- Objectif : observer concrètement READ COMMITTED (défaut PostgreSQL)
--            et le rôle du CHECK (stock >= 0) comme filet de sécurité
--            face à deux transactions concurrentes.
--
-- Mode d'emploi : ouvrir DEUX fenêtres de terminal, chacune connectée
-- via `psql -U mac -d mohdatashop`. Exécuter les blocs dans l'ordre
-- indiqué (SESSION A puis SESSION B), en alternant les fenêtres.
-- ============================================================

-- --- Préparation : mettre le stock du produit 1 à 1 pour forcer le conflit ---
-- (à exécuter une seule fois, dans n'importe quelle session)
UPDATE produits SET stock = 1 WHERE id = 1;


-- ============================================================
-- SESSION A (fenêtre 1)
-- ============================================================

BEGIN;

-- Lit le stock actuel (1)
SELECT id, nom, stock FROM produits WHERE id = 1;

-- Décrémente le stock (simulate une vente)
UPDATE produits SET stock = stock - 1 WHERE id = 1;

-- Ne pas encore COMMIT ici : passer à la SESSION B (fenêtre 2)


-- ============================================================
-- SESSION B (fenêtre 2) — À exécuter PENDANT que A est encore ouverte
-- ============================================================

BEGIN;

-- Cette requête va SE BLOQUER : PostgreSQL fait attendre B tant que
-- A n'a pas fait COMMIT ou ROLLBACK (verrou posé par le UPDATE de A)
UPDATE produits SET stock = stock - 1 WHERE id = 1;

-- Revenir à la SESSION A pour débloquer B


-- ============================================================
-- SESSION A (fenêtre 1) — valider la transaction
-- ============================================================

COMMIT;
-- stock passe de 1 à 0


-- ============================================================
-- SESSION B (fenêtre 2) — la requête se débloque après le COMMIT de A
-- ============================================================

-- B relit alors stock = 0 (READ COMMITTED : B voit l'état validé par A)
-- et tente stock = 0 - 1 = -1

COMMIT;
-- ERREUR ATTENDUE :
-- ERROR: new row for relation "produits" violates check constraint
-- "chk_produits_stock_positif"
-- DETAIL: Failing row contains (..., stock = -1, ...)

-- ============================================================
-- Conclusion du test
-- ============================================================
-- 1. B a bien attendu que A termine (isolation : pas de lecture sale)
-- 2. B a lu la valeur À JOUR après le COMMIT de A (READ COMMITTED)
-- 3. Le CHECK (migration 002) a bloqué le passage en stock négatif
--    -> la transaction de B échoue automatiquement (ROLLBACK implicite)
-- 4. Sans ce CHECK, B aurait réussi et le stock serait passé à -1 :
--    incohérence silencieuse, vente d'un produit qui n'existe plus.

-- --- Nettoyage : remettre le stock à sa valeur d'origine ---
UPDATE produits SET stock = 40 WHERE id = 1;
