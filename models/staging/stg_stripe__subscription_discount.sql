{{ config(enabled=var('stripe__using_subscription_discounts', True)) }}

with fields as (

    {{ stripe.resolve_source_columns(table_name='subscription_discount', staging_columns=stripe.get_subscription_discount_columns()) }}
),

final as (
    
    select
        id as subscription_discount_id,
        checkout_session as checkout_session_id,
        coupon_id,
        customer_id,
        cast(end_at as {{ dbt.type_timestamp() }}) as end_at, -- renamed in macro get_subscription_discount_columns, source column name: end
        invoice_id,
        invoice_item_id,
        cast(start_at as {{ dbt.type_timestamp() }}) as start_at, -- renamed in macro get_subscription_discount_columns, source column name: start
        subscription_id,
        source_relation

    from fields
)

select *
from final