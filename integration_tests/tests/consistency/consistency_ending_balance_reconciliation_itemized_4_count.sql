{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select balance_transaction_id, dispute_reason as dispute_reasons -- we don't have multi-dispute records in our data
    from {{ target.schema }}_stripe_prod.stripe__ending_balance_reconciliation_itemized_4
),

dev as (
    select balance_transaction_id, dispute_reasons
    from {{ target.schema }}_stripe_dev.stripe__ending_balance_reconciliation_itemized_4
)

-- test will return values and fail if the values are different (which they shouldn't be in our test data)
select *
from prod
join dev
    on prod.balance_transaction_id = dev.balance_transaction_id
where prod.dispute_reasons != dev.dispute_reasons