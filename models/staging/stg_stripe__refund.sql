
with fields as (

    select *
    from {{ ref('stg_stripe__refund_tmp') }}
),

final as (
    
    select 
        id as refund_id,
        payment_intent_id,
        balance_transaction_id,
        charge_id,
        {{ stripe.convert_values('amount') }},
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        currency,
        description,
        metadata,
        reason,
        receipt_number,
        status,
        source_relation

        {% if var('stripe__refund_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__refund_metadata')) }}
        {% endif %}

    from fields
)

select * 
from final
