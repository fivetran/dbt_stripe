{{ config(enabled=var('stripe__using_payment_method', True)) }}

with fields as (

    select *
    from {{ ref('stg_stripe__payment_method_tmp') }}
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
