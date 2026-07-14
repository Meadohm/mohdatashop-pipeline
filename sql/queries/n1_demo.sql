-- =========================================================
-- N1 — SELECT, WHERE, ORDER BY, LIMIT, DISTINCT
-- Base : MohdataShop
-- =========================================================

-- 1. SELECT simple : lister tous les produits électroniques
SELECT nom, prix, stock
FROM produits
WHERE categorie = 'Electronique';

-- 2. WHERE avec condition numérique : produits à moins de 10000 CFA
SELECT nom, prix
FROM produits
WHERE prix < 10000;

-- 3. WHERE avec plusieurs conditions (AND / OR) :
--    clients ivoiriens payant par Wave ou Orange
SELECT nom, ville, moyen_paiement
FROM clients
WHERE pays = 'Côte d''Ivoire'
  AND (moyen_paiement = 'Wave' OR moyen_paiement = 'Orange');

-- 4. ORDER BY : produits triés du plus cher au moins cher
SELECT nom, prix
FROM produits
ORDER BY prix DESC;

-- 5. LIMIT : les 3 commandes les plus récentes
SELECT id, date_commande, statut
FROM commandes
ORDER BY date_commande DESC
LIMIT 3;

-- 6. DISTINCT : liste des villes de livraison utilisées (sans doublon)
SELECT DISTINCT ville_livraison
FROM commandes;

-- 7. Combinaison complète : commandes livrées, triées par date, top 5
SELECT id, client_id, date_commande, ville_livraison
FROM commandes
WHERE statut = 'Livrée'
ORDER BY date_commande DESC
LIMIT 5;
