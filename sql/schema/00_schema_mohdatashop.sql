-- =========================================================
-- MohdataShop — Schéma initial (PostgreSQL)
-- Boutique e-commerce fictive, Abidjan, zone UEMOA
-- =========================================================

DROP TABLE IF EXISTS lignes_commande CASCADE;
DROP TABLE IF EXISTS commandes CASCADE;
DROP TABLE IF EXISTS produits CASCADE;
DROP TABLE IF EXISTS clients CASCADE;

-- Clients de la boutique (zone UEMOA)
CREATE TABLE clients (
    id              SERIAL PRIMARY KEY,
    nom             VARCHAR(100) NOT NULL,
    ville           VARCHAR(50)  NOT NULL,
    pays            VARCHAR(50)  NOT NULL,
    telephone       VARCHAR(20),
    moyen_paiement  VARCHAR(20)  NOT NULL -- MTN, Orange, Wave, Carte, Cash
);

-- Catalogue produits
CREATE TABLE produits (
    id          SERIAL PRIMARY KEY,
    nom         VARCHAR(100) NOT NULL,
    categorie   VARCHAR(30)  NOT NULL, -- Electronique, Textile, Alimentaire
    prix        NUMERIC(10,2) NOT NULL,
    stock       INT NOT NULL DEFAULT 0
);

-- Commandes passées
CREATE TABLE commandes (
    id               SERIAL PRIMARY KEY,
    client_id        INT NOT NULL REFERENCES clients(id),
    date_commande    DATE NOT NULL,
    statut           VARCHAR(20) NOT NULL, -- En attente, Livrée, Annulée
    ville_livraison  VARCHAR(50) NOT NULL
);

-- Détail des articles par commande
CREATE TABLE lignes_commande (
    id              SERIAL PRIMARY KEY,
    commande_id     INT NOT NULL REFERENCES commandes(id),
    produit_id      INT NOT NULL REFERENCES produits(id),
    quantite        INT NOT NULL,
    prix_unitaire   NUMERIC(10,2) NOT NULL -- prix figé au moment de la commande
);

-- =========================================================
-- Données d'exemple
-- =========================================================

INSERT INTO clients (nom, ville, pays, telephone, moyen_paiement) VALUES
('Awa Diarra',        'Abidjan',       'Côte d''Ivoire', '+2250701020304', 'Wave'),
('Kouadio Bertin',     'Bouaké',        'Côte d''Ivoire', '+2250701020305', 'Orange'),
('Fatou Ndiaye',       'Dakar',         'Sénégal',        '+2217601020306', 'MTN'),
('Ibrahima Touré',     'Bamako',        'Mali',           '+2237601020307', 'Cash'),
('Aminata Sawadogo',   'Ouagadougou',   'Burkina Faso',   '+2266601020308', 'Orange'),
('Yao Serge',          'Abidjan',       'Côte d''Ivoire', '+2250701020309', 'Carte'),
('Mariam Coulibaly',   'San Pedro',     'Côte d''Ivoire', '+2250701020310', 'Wave'),
('Ousmane Ba',         'Thiès',         'Sénégal',        '+2217601020311', 'MTN');

INSERT INTO produits (nom, categorie, prix, stock) VALUES
('Smartphone Tecno Spark',   'Electronique', 85000, 40),
('Chargeur solaire',         'Electronique', 12000, 60),
('Écouteurs Bluetooth',      'Electronique', 9500,  100),
('Pagne Wax 6 yards',        'Textile',      15000, 30),
('Boubou brodé',             'Textile',      25000, 20),
('Sac en raphia',            'Textile',      7000,  50),
('Attiéké 1kg',               'Alimentaire',  1500,  200),
('Café de Côte d''Ivoire 500g','Alimentaire', 3500,  150),
('Miel local 250ml',         'Alimentaire',  4000,  80),
('Cacao en poudre 1kg',      'Alimentaire',  5000,  90);

INSERT INTO commandes (client_id, date_commande, statut, ville_livraison) VALUES
(1, '2026-06-01', 'Livrée',     'Abidjan'),
(2, '2026-06-02', 'Livrée',     'Bouaké'),
(3, '2026-06-03', 'En attente', 'Dakar'),
(4, '2026-06-04', 'Annulée',    'Bamako'),
(1, '2026-06-10', 'Livrée',     'Abidjan'),
(5, '2026-06-12', 'Livrée',     'Ouagadougou'),
(6, '2026-06-15', 'En attente', 'Abidjan'),
(7, '2026-06-18', 'Livrée',     'San Pedro'),
(3, '2026-06-20', 'Livrée',     'Dakar'),
(8, '2026-06-22', 'En attente', 'Thiès');

INSERT INTO lignes_commande (commande_id, produit_id, quantite, prix_unitaire) VALUES
(1, 1, 1, 85000),
(1, 3, 2, 9500),
(2, 4, 3, 15000),
(3, 7, 10, 1500),
(4, 5, 1, 25000),
(5, 9, 4, 4000),
(6, 2, 2, 12000),
(6, 6, 1, 7000),
(7, 1, 1, 85000),
(8, 8, 5, 3500),
(9, 10, 3, 5000),
(10, 3, 1, 9500);
