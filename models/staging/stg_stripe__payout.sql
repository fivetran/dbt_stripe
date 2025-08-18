
with base as (

    select * 
    from {{ ref('stg_stripe__payout_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__payout_tmp')),
                staging_columns=get_payout_columns()
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
