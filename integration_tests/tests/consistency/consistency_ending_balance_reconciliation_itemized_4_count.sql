{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- this test is to make sure the rows counts are the same between versions
with prod as (
    select 
        count(*) as prod_rows,
        sum(net) as net
    from {{ target.schema }}_stripe_prod.stripe__ending_balance_reconciliation_itemized_4
),

dev as (
    select 
        count(*) as dev_rows,
        sum(net) as net
    from {{ target.schema }}_stripe_dev.stripe__ending_balance_reconciliation_itemized_4
)

-- test will return values and fail if the row counts don't match
select *
from prod
join dev
    on prod.prod_rows != dev.dev_rows
    or prod.net != dev.net