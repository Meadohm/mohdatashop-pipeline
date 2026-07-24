-- =========================================================
-- N6 — RÉCAPITULATIF (validé)
-- Projet pratique : analyse complète MohdataShop
-- Combine : JOIN, CTE, Window Functions, agrégats (N1 → N5)
-- Base : MohdataShop
-- =========================================================

-- Q1 : chiffre d'affaires total par ville de livraison
SELECT c.ville_livraison, SUM(l.quantite * l.prix_unitaire) AS ca_total
FROM commandes c
JOIN lignes_commande l ON c.id = l.commande_id
GROUP BY c.ville_livraison
ORDER BY ca_total DESC;

-- Q2 : rang des clients par chiffre d'affaires total
SELECT cl.nom, SUM(l.quantite * l.prix_unitaire) AS ca_total,
    RANK() OVER (ORDER BY SUM(l.quantite * l.prix_unitaire) DESC) AS rang
FROM clients cl
JOIN commandes c ON cl.id = c.client_id
JOIN lignes_commande l ON c.id = l.commande_id
GROUP BY cl.id, cl.nom
ORDER BY rang;

-- Q3 : 3 produits les plus vendus en quantité
SELECT p.nom, SUM(l.quantite) AS quantite_totale
FROM produits p
JOIN lignes_commande l ON p.id = l.produit_id
GROUP BY p.nom, p.id
ORDER BY quantite_totale DESC
LIMIT 3;

-- Q4 : commandes livrées avec CA supérieur à la moyenne (CTE)
WITH commandes_livrees AS (
    SELECT c.id, cl.nom, c.date_commande, SUM(l.quantite * l.prix_unitaire) AS ca_commande
    FROM commandes c
    JOIN clients cl ON c.client_id = cl.id
    JOIN lignes_commande l ON c.id = l.commande_id
    WHERE c.statut = 'Livrée'
    GROUP BY c.id, cl.nom, c.date_commande
), moyenne_ca AS (
    SELECT AVG(ca_commande) AS moyenne
    FROM commandes_livrees
)
SELECT cl.nom, cl.date_commande, cl.ca_commande
FROM commandes_livrees cl
CROSS JOIN moyenne_ca m
WHERE cl.ca_commande > m.moyenne
ORDER BY cl.ca_commande DESC;

-- Q5 : produit le plus cher et le moins cher par catégorie (Window Functions)
WITH classement AS (
    SELECT categorie, nom,
           RANK() OVER (PARTITION BY categorie ORDER BY prix DESC) AS rang_cher,
           RANK() OVER (PARTITION BY categorie ORDER BY prix ASC) AS rang_moins_cher
    FROM produits
)
SELECT categorie,
       MAX(CASE WHEN rang_cher = 1 THEN nom END) AS produit_plus_cher,
       MAX(CASE WHEN rang_moins_cher = 1 THEN nom END) AS produit_moins_cher
FROM classement
GROUP BY categorie
ORDER BY categorie;
