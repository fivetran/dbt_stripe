{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select count(*) as num_rows
    from {{ target.schema }}_stripe_prod.stripe__daily_overview
),

dev as (
    select count(*) as num_rows
    from {{ target.schema }}_stripe_prod.stripe__daily_overview
)

-- test will return values and fail if the row counts don't match
select *
from prod
full outer join dev
where prod.num_rows != dev.num_rows