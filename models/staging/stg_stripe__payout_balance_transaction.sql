{{ config(enabled=var('stripe__using_payouts', True)) }}

with base as (
    select * 
    from {{ ref('stg_stripe__payout_balance_transaction_tmp') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__payout_balance_transaction_tmp')),
                staging_columns=get_payout_balance_transaction_columns()
            )
        }}

        {{ stripe.apply_source_relation() }}

    from base
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
