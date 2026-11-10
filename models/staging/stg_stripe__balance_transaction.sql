with fields as (

    select *
    from {{ ref('stg_stripe__balance_transaction_tmp') }}
),

final as (
    select 
        id as balance_transaction_id,
        {{ stripe.convert_values('amount') }},
        {{ stripe.convert_values('fee') }},
        {{ stripe.convert_values('net') }},
        cast(available_on as {{ dbt.type_timestamp() }}) as available_on,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        connected_account_id,
        currency,
        description,
        exchange_rate,
        reporting_category,
        source,
        status,
        type,
        source_relation
    from fields
)

select * 
from final
