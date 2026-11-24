{{ config(enabled=var('stripe__using_subscriptions', True)) }}

{%- set price_or_plan = 'price' if var('stripe__using_price', true) else 'plan' -%}

with fields as (

    {{ stripe.resolve_source_columns(table_name=price_or_plan, staging_columns=stripe.get_price_plan_columns()) }}
),

final as (

    select
        cast(id as {{ dbt.type_string() }}) as price_plan_id,
        is_active,
        {{ stripe.convert_values('unit_amount') }},
        currency,
        cast(recurring_interval as {{ dbt.type_string() }}) as recurring_interval,
        cast(recurring_interval_count as {{ dbt.type_int() }}) as recurring_interval_count,
        recurring_usage_type,
        recurring_aggregate_usage,
        metadata,
        nickname,
        product_id,
        billing_scheme,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        is_deleted,
        source_relation

        {% if var('stripe__price_plan_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__price_plan_metadata')) }}
        {% endif %}
        
    from fields
    {{ livemode_predicate() }}
)

select * 
from final

