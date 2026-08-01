select
    produit_id,
    round(avg(note), 1) as note_moyenne,
    count(*) as nb_avis
from {{ source('postgres', 'stg_avis_clients') }}
group by produit_id