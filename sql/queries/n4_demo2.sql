-- =========================================================
-- N4 — CTE (WITH) (partie 2/3)
-- Base : MohdataShop
-- =========================================================

-- 1. CTE simple : chiffre d'affaires par commande
WITH ca_par_commande AS (
    SELECT commande_id, SUM(quantite * prix_unitaire) AS ca
    FROM lignes_commande
    GROUP BY commande_id
)
SELECT * FROM ca_par_commande
ORDER BY ca DESC;

-- 2. CTE + JOIN : chiffre d'affaires par commande, avec le nom du client
WITH ca_par_commande AS (
    SELECT commande_id, SUM(quantite * prix_unitaire) AS ca
    FROM lignes_commande
    GROUP BY commande_id
)
SELECT cl.nom, c.id AS commande_id, cpc.ca
FROM ca_par_commande cpc
JOIN commandes c ON c.id = cpc.commande_id
JOIN clients cl ON cl.id = c.client_id
ORDER BY cpc.ca DESC;

-- 3. CTE + filtre : commandes avec un CA supérieur à 20000
WITH ca_par_commande AS (
    SELECT commande_id, SUM(quantite * prix_unitaire) AS ca
    FROM lignes_commande
    GROUP BY commande_id
)
SELECT * FROM ca_par_commande
WHERE ca > 20000;

-- 4. CTE multiples : CA par client, puis clients au-dessus de la moyenne
WITH ca_par_client AS (
    SELECT c.client_id, SUM(l.quantite * l.prix_unitaire) AS ca_total
    FROM commandes c
    JOIN lignes_commande l ON l.commande_id = c.id
    GROUP BY c.client_id
),
moyenne_ca AS (
    SELECT AVG(ca_total) AS moyenne FROM ca_par_client
)
SELECT cl.nom, cpc.ca_total
FROM ca_par_client cpc
JOIN clients cl ON cl.id = cpc.client_id
JOIN moyenne_ca m ON cpc.ca_total > m.moyenne;

