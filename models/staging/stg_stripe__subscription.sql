{{ config(enabled=var('stripe__using_subscriptions', True)) }}

with fields as (

    select *
    from {{ ref('stg_stripe__subscription_tmp') }}
),

final as (
    
    select 
        id as subscription_id,
        latest_invoice_id,
        customer_id,
        default_payment_method_id,
        pending_setup_intent_id,
        status,
        billing,
        billing_cycle_anchor,
        cast(cancel_at as {{ dbt.type_timestamp() }}) as cancel_at,
        cancel_at_period_end as is_cancel_at_period_end,
        cast(canceled_at as {{ dbt.type_timestamp() }}) as canceled_at,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        cast(current_period_start as {{ dbt.type_timestamp() }}) as current_period_start,
        cast(current_period_end as {{ dbt.type_timestamp() }}) as current_period_end,
        days_until_due,
        metadata,
        cast(start_date as {{ dbt.type_timestamp() }}) as start_date_at,
        cast(ended_at as {{ dbt.type_timestamp() }}) as ended_at,
        pause_collection_behavior,
        cast(pause_collection_resumes_at as {{ dbt.type_timestamp() }}) as pause_collection_resumes_at,
        source_relation
        
        {% if var('stripe__subscription_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__subscription_metadata')) }}
        {% endif %}

    from fields
    {{ livemode_predicate() }}
    {% if var('stripe__using_subscription_history', true) %}
        and coalesce(_fivetran_active, true)
    {% endif %}
)

select * 
from final
