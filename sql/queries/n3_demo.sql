-- =========================================================
-- N3 — INNER JOIN, LEFT JOIN, RIGHT JOIN (partie 1/2)
-- Base : MohdataShop
-- =========================================================

-- 1. INNER JOIN : commandes avec le nom du client
SELECT c.id AS commande_id, cl.nom, c.date_commande, c.statut
FROM commandes c
INNER JOIN clients cl 
ON c.client_id = cl.id;

-- 2. INNER JOIN + WHERE : commandes livrées avec le nom du client
SELECT c.id AS commande_id, cl.nom, c.date_commande
FROM commandes c
INNER JOIN clients cl 
ON c.client_id = cl.id
WHERE c.statut = 'Livrée';

-- 3. LEFT JOIN : tous les clients, avec ou sans commande
SELECT cl.nom, c.id AS commande_id
FROM clients cl
LEFT JOIN commandes c ON cl.id = c.client_id;

-- 4. LEFT JOIN + IS NULL : clients qui n'ont jamais commandé
SELECT cl.nom
FROM clients cl
LEFT JOIN commandes c ON cl.id = c.client_id
WHERE c.id IS NULL;

-- 5. RIGHT JOIN : équivalent inversé du LEFT JOIN (rarement utilisé)
-- Ici : toutes les commandes, même si le client n'existait plus (cas théorique)
SELECT cl.nom, c.id AS commande_id
FROM clients cl
RIGHT JOIN commandes c ON cl.id = c.client_id;