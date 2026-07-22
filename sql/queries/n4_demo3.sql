-- =========================================================
-- N4 — Window Functions : OVER, ROW_NUMBER, RANK (partie 3/3)
-- Base : MohdataShop
-- =========================================================

-- 1. PARTITION BY : prix moyen par catégorie affiché sur chaque ligne
SELECT nom, categorie, prix,
       ROUND(AVG(prix) OVER (PARTITION BY categorie), 2) AS prix_moyen_categorie
FROM produits;

-- 2. ROW_NUMBER : numéroter les commandes de chaque client par date
SELECT client_id, id AS commande_id, date_commande,
       ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY date_commande) AS num_commande
FROM commandes;

-- 3. RANK : classer les produits par prix au sein de leur catégorie
SELECT nom, categorie, prix,
       RANK() OVER (PARTITION BY categorie ORDER BY prix DESC) AS rang_prix
FROM produits;

-- 4. Combinaison : le produit le plus cher de chaque catégorie
WITH classement AS (
    SELECT nom, categorie, prix,
           RANK() OVER (PARTITION BY categorie ORDER BY prix DESC) AS rang_prix
    FROM produits
)
SELECT nom, categorie, prix
FROM classement
WHERE rang_prix = 1;

