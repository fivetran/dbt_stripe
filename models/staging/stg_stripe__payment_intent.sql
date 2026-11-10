with fields as (

    {{ stripe.resolve_source_columns(table_name='payment_intent', staging_columns=stripe.get_payment_intent_columns()) }}
),

final as (
    
    select 
        id as payment_intent_id,
        {{ stripe.convert_values('amount') }},
        {{ stripe.convert_values('amount_capturable') }},
        {{ stripe.convert_values('amount_received') }},
        {{ stripe.convert_values('application_fee_amount') }},
        application,
        cast(canceled_at as {{ dbt.type_timestamp() }}) as canceled_at,
        cancellation_reason,
        capture_method,
        confirmation_method,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        currency,
        customer_id,
        description,
        metadata,
        payment_method_id,
        receipt_email,
        statement_descriptor,
        status,
        source_relation

        {% if var('stripe__payment_intent_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__payment_intent_metadata')) }}
        {% endif %}

    from fields
    {{ livemode_predicate() }}
)

select * 
from final
