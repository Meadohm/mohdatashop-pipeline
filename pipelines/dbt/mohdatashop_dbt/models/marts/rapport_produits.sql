{{ config(materialized='table') }}

select
    v.produit_id,
    v.produit,
    v.categorie,
    v.quantite_vendue,
    v.chiffre_affaires,
    coalesce(a.note_moyenne, 0) as note_moyenne,
    coalesce(a.nb_avis, 0) as nb_avis,
    coalesce(act.nb_consultations, 0) as nb_consultations
from {{ ref('stg_ventes') }} v
left join {{ ref('stg_avis') }} a on a.produit_id = v.produit_id
left join {{ ref('stg_activite') }} act on act.produit_id = v.produit_id
order by v.chiffre_affaires desc