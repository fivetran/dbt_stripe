with fields as (

    {{ stripe.resolve_source_columns(table_name='subscription_item', staging_columns=stripe.get_subscription_item_columns()) }}
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
