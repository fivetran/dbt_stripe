with base as (
    select * 
    from {{ ref('stg_stripe__balance_transaction_tmp') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__balance_transaction_tmp')),
                staging_columns=get_balance_transaction_columns()
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
