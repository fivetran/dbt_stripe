
with base as (

    select * 
    from {{ ref('stg_stripe__discount_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__discount_tmp')),
                staging_columns=get_discount_columns()
            )
        }}

        {{ fivetran_utils.source_relation(
            union_schema_variable='stripe_union_schemas', 
            union_database_variable='stripe_union_databases') 
        }}

    from base
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
