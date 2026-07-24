-- =========================================================
-- N5 — EXPLAIN, CREATE INDEX, EXPLAIN ANALYZE
-- Base : MohdataShop
-- Note : jeu de données trop petit pour un gain réel (Postgres
-- préfère toujours un Seq Scan en dessous de quelques milliers
-- de lignes). Objectif ici = syntaxe + lecture de plan.
-- =========================================================

-- 1. EXPLAIN : plan d'exécution AVANT index
EXPLAIN
SELECT nom, ville
FROM clients
WHERE moyen_paiement = 'MTN';

-- 2. CREATE INDEX : indexer la colonne filtrée
CREATE INDEX idx_clients_moyen_paiement ON clients (moyen_paiement);

-- 3. EXPLAIN à nouveau : Postgres choisit-il l'index ? (probablement non, table trop petite)
EXPLAIN
SELECT nom, ville
FROM clients
WHERE moyen_paiement = 'MTN';

-- 4. EXPLAIN ANALYZE : exécution réelle + timing
EXPLAIN ANALYZE
SELECT nom, ville
FROM clients
WHERE moyen_paiement = 'MTN';

-- 5. Index composite : utile si on filtre souvent sur 2 colonnes ensemble
CREATE INDEX idx_commandes_client_statut ON commandes (client_id, statut);

-- 6. Lister les index existants sur une table
-- (commande psql, pas du SQL standard)
-- \d clients

-- crée un index sur produits.categorie, puis lance EXPLAIN sur une requête qui filtre WHERE categorie = 'Alimentaire'. Colle-moi le plan obtenu (même si Seq Scan, c'est normal)
CREATE INDEX idx_produits_categorie ON produits (categorie);
EXPLAIN
SELECT * FROM produits WHERE categorie = 'Alimentaire';