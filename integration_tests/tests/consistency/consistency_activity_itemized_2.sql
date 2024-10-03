{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select balance_transaction_id, dispute_id as dispute_ids -- we don't have multi-dispute records in our data
    from {{ target.schema }}_stripe_prod.stripe__activity_itemized_2
),

dev as (
    select balance_transaction_id, dispute_ids
    from {{ target.schema }}_stripe_dev.stripe__activity_itemized_2
)

-- test will return values and fail if the values are different (which they shouldn't be in our test data)
select *
from prod
join dev
    on prod.balance_transaction_id = dev.balance_transaction_id
where prod.dispute_ids != dev.dispute_ids