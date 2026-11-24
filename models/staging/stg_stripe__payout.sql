{{ config(enabled=var('stripe__using_payouts', True)) }}

with fields as (

    {{ stripe.resolve_source_columns(table_name='payout', staging_columns=stripe.get_payout_columns()) }}
),

final as (
    
    select 
        id as payout_id,
        {{ stripe.convert_values('amount') }},
        cast(arrival_date as {{ dbt.type_timestamp() }}) as arrival_date_at,
        automatic as is_automatic,
        balance_transaction_id, -- payout to balance_transaction is 1:many. This is the latest balance_transaction linked to the payout.
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        currency,
        description,
        destination_bank_account_id,
        destination_card_id,
        metadata,
        method,
        source_type,
        status,
        type,
        source_relation

        {% if var('stripe__payout_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__payout_metadata')) }}
        {% endif %}

    from fields
    {{ livemode_predicate() }}
)

select * 
from final
