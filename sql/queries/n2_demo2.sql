-- =========================================================
-- N2 — GROUP BY, HAVING (partie 2/2)
-- Base : MohdataShop
-- =========================================================

-- 1. GROUP BY simple : nombre de produits par catégorie
SELECT categorie, COUNT(*) AS nb_produits
FROM produits
GROUP BY categorie;

-- 2. GROUP BY + SUM : chiffre d'affaires par produit
SELECT produit_id, SUM(quantite * prix_unitaire) AS ca_produit
FROM lignes_commande
GROUP BY produit_id
ORDER BY ca_produit DESC;

-- 3. GROUP BY + AVG : prix moyen par catégorie
SELECT categorie, ROUND(AVG(prix), 2) AS prix_moyen
FROM produits
GROUP BY categorie;

-- 4. HAVING : catégories avec plus de 3 produits
SELECT categorie, COUNT(*) AS nb_produits
FROM produits
GROUP BY categorie
HAVING COUNT(*) > 3;

-- 5. GROUP BY + HAVING combiné : clients ayant commandé plus d'une fois
SELECT client_id, COUNT(*) AS nb_commandes
FROM commandes
GROUP BY client_id
HAVING COUNT(*) > 1;
