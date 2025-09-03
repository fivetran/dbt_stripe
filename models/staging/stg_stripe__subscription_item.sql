{{ config(enabled=var('stripe__using_subscriptions', True)) }}

with base as (

    select * 
    from {{ ref('stg_stripe__subscription_item_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__subscription_item_tmp')),
                staging_columns=get_subscription_item_columns()
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
        id as subscription_item_id,
        plan_id,
        subscription_id,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        current_period_start,
        current_period_end,
        metadata,
        quantity,
        source_relation
        
        {% if var('stripe__subscription_item_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__subscription_item_metadata')) }}
        {% endif %}

    from fields
)

select * 
from final
