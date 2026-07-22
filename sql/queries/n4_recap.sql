-- =========================================================
-- N4 — RÉCAPITULATIF (validé)
-- Concepts : sous-requêtes (scalaire, IN, EXISTS), CTE (WITH), Window Functions
-- Base : MohdataShop
-- =========================================================

-- Exercice 1 : clients n'ayant jamais commandé (NOT EXISTS)
SELECT nom
FROM clients cl
WHERE NOT EXISTS (
    SELECT 1 FROM commandes c WHERE c.client_id = cl.id
);

-- Exercice 2 : clients ayant passé plus d'une commande (CTE)
WITH nb_commandes_par_client AS (
    SELECT c.client_id, COUNT(*) AS nb_commandes
    FROM commandes c
    GROUP BY c.client_id
)
SELECT cl.nom, nbc.nb_commandes
FROM nb_commandes_par_client nbc
JOIN clients cl ON cl.id = nbc.client_id
WHERE nbc.nb_commandes > 1;

-- Exercice 3 : commande la plus récente par client (ROW_NUMBER)
SELECT client_id, id AS commande_id, date_commande
FROM (
    SELECT client_id, id, date_commande,
           ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY date_commande DESC) AS rang
    FROM commandes
) AS sous_requete
WHERE rang = 1;
