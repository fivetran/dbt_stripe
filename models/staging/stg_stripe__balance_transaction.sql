with fields as (

    {{ stripe.resolve_source_columns(table_name='balance_transaction', staging_columns=stripe.get_balance_transaction_columns()) }}
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
