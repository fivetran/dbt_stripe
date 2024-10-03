{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with staging_model as (
    select 
        count(*) as row_count,
        sum(amount) as balance_transaction_amount,
        sum(net) as balance_transaction_net
    from {{ ref('stg_stripe__balance_transaction') }}
),

end_model as (
    select 
        count(*) as row_count,
        sum(balance_transaction_amount) as balance_transaction_amount,
        sum(balance_transaction_net) as balance_transaction_net
    from {{ ref('stripe__balance_transactions') }}
)

select *
from staging_model
join end_model
    on staging_model.row_count != end_model.row_count
    or staging_model.balance_transaction_amount != end_model.balance_transaction_amount
    or staging_model.balance_transaction_net != end_model.balance_transaction_net