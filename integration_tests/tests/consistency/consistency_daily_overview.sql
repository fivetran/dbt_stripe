{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select *
    from {{ target.schema }}_stripe_prod.stripe__daily_overview
),

dev as (
    select *
    from {{ target.schema }}_stripe_prod.stripe__daily_overview
)

-- test will fail if any rows from prod are not found in dev
select * from prod
except
select * from dev

union all

-- test will fail if any rows from dev are not found in prod
select * from dev
except
select * from prod

limit 100 -- this is sufficient to generate a failure and prevent too large a table