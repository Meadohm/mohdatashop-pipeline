-- =========================================================
-- N3 — FULL JOIN, CROSS JOIN, SELF JOIN (partie 2/2)
-- Base : MohdataShop
-- =========================================================

-- 1. FULL JOIN : tous les clients + toutes les commandes, matchés ou non
SELECT cl.nom, c.id AS commande_id
FROM clients cl
FULL JOIN commandes c ON cl.id = c.client_id;

-- 2. CROSS JOIN : produit cartésien (attention, explose vite en volume)
-- Ici : toutes les combinaisons produit x ville de livraison utilisées
SELECT p.nom AS produit, DISTINCT_villes.ville_livraison
FROM produits p
CROSS JOIN (SELECT DISTINCT ville_livraison FROM commandes) AS DISTINCT_villes
LIMIT 10;

-- 3. SELF JOIN : clients de la même ville (paires distinctes)
SELECT a.nom AS client_1, b.nom AS client_2, a.ville
FROM clients a
JOIN clients b ON a.ville = b.ville AND a.id < b.id;
