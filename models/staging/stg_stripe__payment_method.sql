{{ config(enabled=var('stripe__using_payment_method', True)) }}

with base as (

    select * 
    from {{ ref('stg_stripe__payment_method_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__payment_method_tmp')),
                staging_columns=get_payment_method_columns()
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
        id as payment_method_id,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        customer_id,
        metadata,
        type,
        source_relation

        {% if var('stripe__payment_method_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__payment_method_metadata')) }}
        {% endif %}

    from fields
    {{ livemode_predicate() }}
)

select * 
from final
