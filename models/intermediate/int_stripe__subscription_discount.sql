{{ config(enabled=var('stripe__using_subscription_discounts', True) and var('stripe__using_coupons', True)) }}

with subscription_discount as (

    select *
    from {{ ref('stg_stripe__subscription_discount') }}

),

coupon as (

    select *
    from {{ ref('stg_stripe__coupon') }}

),

subscription_discount_schedule as (

    select
        subscription_discount.source_relation,
        subscription_discount.subscription_id,
        subscription_discount.customer_id,
        subscription_discount.coupon_id,
        subscription_discount.start_at,
        subscription_discount.end_at,
        cast({{ dbt.date_trunc('month', 'subscription_discount.start_at') }} as date) as start_month,
        coupon.percent_off,
        coupon.amount_off,
        coupon.duration,
        coupon.duration_in_months,
        coupon.currency as coupon_currency
    from subscription_discount
    left join coupon
      on subscription_discount.source_relation = coupon.source_relation
      and subscription_discount.coupon_id = coupon.coupon_id
    where subscription_discount.coupon_id is not null
      and subscription_discount.start_at is not null

),

subscription_discount_bounds as (

    select
        subscription_discount_schedule.*,

        case
            when duration = 'forever' then null

            when duration = 'once' then
                cast({{ dbt.dateadd('month', 1, dbt.date_trunc('month', 'subscription_discount_schedule.start_at')) }} as date)

            when duration = 'repeating' then
                cast({{ dbt.dateadd(
                    'month',
                    'coalesce(subscription_discount_schedule.duration_in_months, 1)',
                    dbt.date_trunc('month', 'subscription_discount_schedule.start_at')
                ) }} as date)

            else null
        end as end_month

    from subscription_discount_schedule

)

select *
from subscription_discount_bounds