{{ config(enabled=var('stripe__using_subscriptions', True)) }}

with price_plan as (

    select *
    from {{ ref('stg_stripe__price_plan_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__price_plan_tmp')),
                staging_columns=get_price_plan_columns()
            )
        }}

        {{ fivetran_utils.source_relation(
            union_schema_variable='stripe_union_schemas', 
            union_database_variable='stripe_union_databases') 
        }}

    from price_plan
),

final as (

    select
        id as price_plan_id,
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

