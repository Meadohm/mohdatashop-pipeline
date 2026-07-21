-- =========================================================
-- N3 — RÉCAPITULATIF (validé)
-- Concepts : INNER, LEFT, RIGHT, FULL, CROSS, SELF JOIN
-- Base : MohdataShop
-- =========================================================

-- Exercice 1 : clients + nombre de commandes (y compris 0)
SELECT cl.nom, COUNT(c.id) AS nb_commandes
FROM clients cl
LEFT JOIN commandes c ON cl.id = c.client_id
GROUP BY cl.id, cl.nom;

-- Exercice 2 : paires de produits de la même catégorie (SELF JOIN)
SELECT p1.nom AS produit_1, p2.nom AS produit_2, p1.categorie
FROM produits p1
JOIN produits p2 ON p1.categorie = p2.categorie AND p1.id < p2.id;
