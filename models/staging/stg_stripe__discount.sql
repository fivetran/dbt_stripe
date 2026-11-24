
with fields as (

    {{ stripe.resolve_source_columns(table_name='discount', staging_columns=stripe.get_discount_columns()) }}
),

final as (
    
    select
        id as discount_id,
        type,
        type_id,
        {{ stripe.convert_values('amount') }},
        checkout_session_id,
        checkout_session_line_item_id,
        coupon_id,
        credit_note_line_item_id,
        customer_id,
        cast(end_at as {{ dbt.type_timestamp() }}) as end_at, -- renamed in macro get_discount_columns, source column name: end
        invoice_id,
        invoice_item_id,
        promotion_code,
        cast(start_at as {{ dbt.type_timestamp() }}) as start_at, -- renamed in macro get_discount_columns, source column name: start
        subscription_id,
        source_relation

    from fields
)

select *
from final
