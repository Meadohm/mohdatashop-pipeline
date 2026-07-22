-- =========================================================
-- N5 — RÉCAPITULATIF (validé)
-- Concepts : EXPLAIN, CREATE INDEX, EXPLAIN ANALYZE
-- Base : MohdataShop
-- Note : jeu de données trop petit pour un gain réel mesurable
-- (Postgres privilégie Seq Scan sous quelques milliers de lignes).
-- Objectif ici = syntaxe + lecture de plan, réflexe :
-- EXPLAIN (diagnostic) AVANT CREATE INDEX (remède).
-- =========================================================

-- Exercice : index sur produits.categorie + lecture du plan
CREATE INDEX idx_produits_categorie ON produits (categorie);

EXPLAIN
SELECT * FROM produits WHERE categorie = 'Alimentaire';

-- Résultat observé : Seq Scan (index ignoré, table trop petite)
-- Seq Scan on produits  (cost=0.00..12.88 rows=1 width=320)
--   Filter: ((categorie)::text = 'Alimentaire'::text)
