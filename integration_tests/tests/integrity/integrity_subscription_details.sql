{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with staging_model as (
    select 
        count(*) as row_count,
        sum(days_until_due) as days_until_due,
        count(distinct customer_id) as distinct_customer_count
    from {{ ref('stg_stripe__subscription') }}
),

end_model as (
    select 
        count(*) as row_count,
        sum(days_until_due) as days_until_due,
        count(distinct customer_id) as distinct_customer_count
    from {{ ref('stripe__subscription_details') }}
)

select *
from staging_model
join end_model
    on staging_model.row_count != end_model.row_count
    or staging_model.days_until_due != end_model.days_until_due
    or staging_model.distinct_customer_count != end_model.distinct_customer_count