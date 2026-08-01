select
    metadata_produit_id::int as produit_id,
    count(*) as nb_consultations
from {{ source('postgres', 'stg_logs_activite') }}
where action = 'consultation_produit'
group by metadata_produit_id