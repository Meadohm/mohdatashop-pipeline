-- =========================================================
-- N2 — COUNT, SUM, AVG (partie 1/2)
-- Base : MohdataShop
-- =========================================================

-- 1. COUNT : nombre total de commandes
SELECT COUNT(*) AS nb_commandes
FROM commandes;

-- 2. COUNT avec condition : nombre de commandes livrées
SELECT COUNT(*) AS nb_livrees
FROM commandes
WHERE statut = 'Livrée';

-- 3. SUM : chiffre d'affaires total (toutes lignes de commande)
SELECT SUM(quantite * prix_unitaire) AS ca_total
FROM lignes_commande;

-- 4. AVG : prix moyen des produits
SELECT AVG(prix) AS prix_moyen
FROM produits;

-- 5. AVG arrondi (plus lisible)
SELECT ROUND(AVG(prix), 2) AS prix_moyen
FROM produits;
