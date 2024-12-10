{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- this test is to make sure the rows counts are the same between versions
with prod as (
    select 
        count(*) as prod_rows,
        sum(customer_facing_amount) as customer_facing_amount,
        sum(balance_transaction_amount) as balance_transaction_amount,
        sum(balance_transaction_net) as balance_transaction_net
    from {{ target.schema }}_stripe_prod.stripe__balance_transactions
),

dev as (
    select 
        count(*) as dev_rows,
        sum(customer_facing_amount) as customer_facing_amount,
        sum(balance_transaction_amount) as balance_transaction_amount,
        sum(balance_transaction_net) as balance_transaction_net
    from {{ target.schema }}_stripe_dev.stripe__balance_transactions
)

-- test will return values and fail if the row counts don't match
select *
from prod
join dev
    on prod.prod_rows != dev.dev_rows
    or prod.customer_facing_amount != dev.customer_facing_amount
    or prod.balance_transaction_amount != dev.balance_transaction_amount
    or prod.balance_transaction_net != dev.balance_transaction_net