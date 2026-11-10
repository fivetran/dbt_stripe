
with fields as (

    select *
    from {{ ref('stg_stripe__fee_tmp') }}
),

final as (
    
    select 
        balance_transaction_id,
        index,
        {{ stripe.convert_values('amount') }},
        application,
        currency,
        description,
        type,
        source_relation

    from fields
)

select * 
from final
