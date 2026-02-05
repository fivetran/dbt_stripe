{{ config(enabled=var('stripe__using_subscriptions', True)) }}

with product as (

    select * 
    from {{ ref('stg_stripe__product_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__product_tmp')),
                staging_columns=get_product_columns()
            )
        }}

        {{ stripe.apply_source_relation() }}

    from product
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

