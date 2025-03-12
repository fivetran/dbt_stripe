{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false) and var('stripe__standardized_billing_model_enabled', false)
) }}

-- this test is to make sure the rows counts are the same between versions
with prod as (
    select 
        count(*) as prod_rows,
        sum(unit_amount) as unit_amount
    from {{ target.schema }}_stripe_prod.stripe__line_item_enhanced
),

dev as (
    select 
        count(*) as dev_rows,
        sum(unit_amount) as unit_amount
    from {{ target.schema }}_stripe_dev.stripe__line_item_enhanced
)

-- test will return values and fail if the row counts don't match
select *
from prod
join dev
    on prod.prod_rows != dev.dev_rows
    or prod.unit_amount != dev.unit_amount