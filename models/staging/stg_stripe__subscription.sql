{{ config(enabled=var('stripe__using_subscriptions', True)) }}

with base as (

    select * 
    from {{ ref('stg_stripe__subscription_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__subscription_tmp')),
                staging_columns=get_subscription_columns()
            )
        }}

        {{ stripe.apply_source_relation() }}
        
    from base
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
    {% if var('stripe__using_subscription_history', stripe.does_table_exist('subscription_history')=='exists') %}
        and coalesce(_fivetran_active, true)
    {% endif %}
)

select * 
from final
