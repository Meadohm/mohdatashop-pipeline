-- ============================================================
-- Migration 001 : Normalisation de la colonne categorie
-- Contexte : produits.categorie était un champ texte libre (varchar)
--            -> duplication du nom de catégorie sur chaque produit,
--               aucune contrainte d'intégrité, renommage impossible
--               proprement (anomalie de mise à jour, cf. N1 - 3NF)
-- Objectif : extraire une table categories + FK produits.categorie_id
-- ============================================================

BEGIN;

-- 1. Création de la table categories
CREATE TABLE categories (
    id  SERIAL PRIMARY KEY,
    nom VARCHAR(100) UNIQUE NOT NULL
);

-- 2. Extraction des catégories distinctes déjà présentes dans produits
INSERT INTO categories (nom)
SELECT DISTINCT categorie
FROM produits
WHERE categorie IS NOT NULL;

-- 3. Ajout de la colonne categorie_id (nullable pour l'instant, le temps du backfill)
ALTER TABLE produits ADD COLUMN categorie_id INT;

-- 4. Backfill : liaison de chaque produit à sa catégorie
UPDATE produits p
SET categorie_id = c.id
FROM categories c
WHERE p.categorie = c.nom;

-- 5. Contrainte FK + NOT NULL une fois le backfill vérifié
ALTER TABLE produits
    ALTER COLUMN categorie_id SET NOT NULL,
    ADD CONSTRAINT fk_produits_categorie
        FOREIGN KEY (categorie_id) REFERENCES categories(id);

-- 6. Suppression de l'ancienne colonne texte
ALTER TABLE produits DROP COLUMN categorie;

COMMIT;

-- ============================================================
-- Rollback manuel (si besoin de revenir en arrière) :
-- ALTER TABLE produits ADD COLUMN categorie VARCHAR(100);
-- UPDATE produits p SET categorie = c.nom
--     FROM categories c WHERE p.categorie_id = c.id;
-- ALTER TABLE produits DROP CONSTRAINT fk_produits_categorie;
-- ALTER TABLE produits DROP COLUMN categorie_id;
-- DROP TABLE categories;
-- ============================================================
