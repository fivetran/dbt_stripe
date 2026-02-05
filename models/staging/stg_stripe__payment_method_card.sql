{{ config(enabled=var('stripe__using_payment_method', True)) }}

with base as (

    select * 
    from {{ ref('stg_stripe__payment_method_card_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__payment_method_card_tmp')),
                staging_columns=get_payment_method_card_columns()
            )
        }}

        {{ stripe.apply_source_relation() }}
        
    from base
),

final as (
    
    select 
        payment_method_id,
        brand,
        funding,
        charge_id,
        type,
        wallet_type,
        three_d_secure_authentication_flow,
        three_d_secure_result,
        three_d_secure_result_reason,
        three_d_secure_version,
        source_relation

    from fields
)

select * 
from final
