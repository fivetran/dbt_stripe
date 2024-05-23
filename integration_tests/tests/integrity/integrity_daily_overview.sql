{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- this test is to make sure there is no fanout between the spine and the daily_overview
with spine as (
    select count(*) as spine_count
    from {{ target.schema }}_stripe_dev.int_stripe__date_spine
),

daily_overview as (
    select count(*) as daily_overview_count
    from {{ target.schema }}_stripe_dev.stripe__daily_overview
)

-- test will return values and fail if the row counts don't match
select *
from spine
join daily_overview
    on spine.spine_count != daily_overview.daily_overview_count