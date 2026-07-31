select
    p.id as produit_id,
    p.nom as produit,
    c.nom as categorie,
    sum(lc.quantite) as quantite_vendue,
    sum(lc.quantite * lc.prix_unitaire) as chiffre_affaires
from {{ source("postgres", "lignes_commande") }} lc
join {{ source("postgres", "produits") }} p on p.id = lc.produit_id
join {{ source("postgres", "categories") }} c on c.id = p.categorie_id
group by p.id, p.nom, c.nom
order by chiffre_affaires desc
