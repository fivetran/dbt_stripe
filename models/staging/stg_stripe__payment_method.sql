{{ config(enabled=var('stripe__using_payment_method', True)) }}

with fields as (

    {{ stripe.resolve_source_columns(table_name='payment_method', staging_columns=stripe.get_payment_method_columns()) }}
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
