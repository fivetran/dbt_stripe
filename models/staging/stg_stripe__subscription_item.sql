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

        {{ stripe.apply_source_relation() }}
        
    from base
),

final as (
    
    select 
        id as subscription_item_id,
        cast(plan_id as {{ dbt.type_string() }}) as plan_id,
        subscription_id,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        cast(current_period_start as {{ dbt.type_timestamp() }}) as current_period_start,
        cast(current_period_end as {{ dbt.type_timestamp() }}) as current_period_end,
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
