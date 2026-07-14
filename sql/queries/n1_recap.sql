-- =========================================================
-- N1 — RÉCAPITULATIF (validé)
-- Concepts : SELECT, WHERE, ORDER BY, LIMIT, DISTINCT
-- Base : MohdataShop
-- =========================================================

-- Exercice 1 : clients payant par MTN, triés par ville
SELECT nom, ville
FROM clients
WHERE moyen_paiement = 'MTN'
ORDER BY ville;

-- Exercice 2 : 3 produits les moins chers
SELECT nom, prix
FROM produits
ORDER BY prix
LIMIT 3;

-- Exercice 3 : catégories de produits distinctes
SELECT DISTINCT categorie
FROM produits;
