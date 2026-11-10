{{ config(enabled=var('stripe__using_payouts', True)) }}

with fields as (

    {{ stripe.resolve_source_columns(table_name='payout_balance_transaction', staging_columns=stripe.get_payout_balance_transaction_columns()) }}
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
