{{ config(enabled=var('stripe__using_transfers', True)) }}

with fields as (

    select *
    from {{ ref('stg_stripe__transfer_tmp') }}
),

final as (
    
    select
        id as transfer_id,
        {{ stripe.convert_values('amount', alias='transfer_amount') }},
        {{ stripe.convert_values('amount_reversed', alias='transfer_amount_reversed') }},
        balance_transaction_id,
        cast(created as {{ dbt.type_timestamp() }}) as transfer_created_at,
        currency as transfer_currency,
        description as transfer_description,
        destination as transfer_destination,
        destination_payment,
        destination_payment_id,
        metadata as transfer_metadata,
        reversed as transfer_is_reversed,
        source_transaction,
        source_transaction_id,
        source_type,
        transfer_group,
        source_relation
        
        {% if var('stripe__transfer_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__transfer_metadata')) }}
        {% endif %}

    from fields
    {{ livemode_predicate() }}
)

select *
from final 
