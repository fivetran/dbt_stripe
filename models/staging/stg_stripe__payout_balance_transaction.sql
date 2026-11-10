{{ config(enabled=var('stripe__using_payouts', True)) }}

with fields as (

    select *
    from {{ ref('stg_stripe__payout_balance_transaction_tmp') }}
),

final as (
    select 
        payout_id,
        balance_transaction_id,
        source_relation
    from fields
)

select * 
from final
