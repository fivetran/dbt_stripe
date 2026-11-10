{{ config(enabled=var('stripe__using_payment_method', True)) }}

with fields as (

    {{ stripe.resolve_source_columns(table_name='payment_method_card', staging_columns=stripe.get_payment_method_card_columns()) }}
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
