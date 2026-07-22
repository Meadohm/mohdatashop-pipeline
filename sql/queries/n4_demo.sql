-- =========================================================
-- N4 — Sous-requêtes : scalaire, IN, EXISTS (partie 1/3)
-- Base : MohdataShop
-- =========================================================

-- 1. Sous-requête scalaire : produits plus chers que le prix moyen
SELECT nom, prix
FROM produits
WHERE prix > (SELECT AVG(prix) FROM produits);

-- 2. Sous-requête scalaire dans le SELECT : écart au prix moyen
SELECT nom, prix, prix - (SELECT AVG(prix) FROM produits) AS ecart_moyenne
FROM produits;

-- 3. Sous-requête IN : clients ayant passé au moins une commande
SELECT nom
FROM clients
WHERE id IN (SELECT DISTINCT client_id FROM commandes);

-- 4. Sous-requête NOT IN : produits jamais commandés
SELECT nom
FROM produits
WHERE id NOT IN (SELECT DISTINCT produit_id FROM lignes_commande);

-- 5. Sous-requête EXISTS : équivalent plus performant du IN (question 3)
SELECT nom
FROM clients cl
WHERE EXISTS (
    SELECT 1 FROM commandes c WHERE c.client_id = cl.id
);
