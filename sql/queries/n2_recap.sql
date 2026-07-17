-- =========================================================
-- N2 — RÉCAPITULATIF (validé)
-- Concepts : COUNT, SUM, AVG, GROUP BY, HAVING
-- Base : MohdataShop
-- =========================================================

-- Exercice 1 : nombre de clients basés en Côte d'Ivoire
SELECT COUNT(*) AS nb_clients_ci
FROM clients
WHERE pays = 'Côte d''Ivoire';

-- Exercice 2 : nombre de commandes par statut, trié décroissant
SELECT statut, COUNT(*) AS nb_commandes
FROM commandes
GROUP BY statut
ORDER BY nb_commandes DESC;
