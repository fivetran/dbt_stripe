{{ config(enabled=var('stripe__using_subscriptions', True)) }}

with fields as (

    {{ stripe.resolve_source_columns(table_name='product', staging_columns=stripe.get_product_columns()) }}
),

final as (

    select 
        id as product_id,
        is_active, -- renamed in macro get_product_columns, source column name: active
        attributes,
        caption,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        cast(deactivate_on as {{ dbt.type_timestamp() }}) as deactivate_at,
        description,
        images,
        is_deleted,
        name,
        shippable,
        statement_descriptor,
        type,
        unit_label,
        updated,
        url,
        source_relation

    from fields
    {{ livemode_predicate() }}
)

select * 
from final

