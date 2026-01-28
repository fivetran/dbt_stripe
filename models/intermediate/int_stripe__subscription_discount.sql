{{ config(enabled=var('stripe__using_coupons', True)) }}

with discount as (

    select *
    from {{ ref('stg_stripe__discount') }}

),

coupon as (

    select *
    from {{ ref('stg_stripe__coupon') }}

),

/*
Aggressive coupon-based dedupe to avoid double counting event representations
(e.g., invoice_line_item + upcoming_invoice_line_item for same effective discount).

We collapse to a "subscription + coupon + start_month" episode and keep ONE effective
discount amount for that episode.

Using MAX(discount_amount) prevents double counting when duplicates exist.
*/
discount_dedupe as (

    select
        source_relation,
        subscription_id,
        customer_id,
        coupon_id,
        cast({{ dbt.date_trunc('month', 'discount.start_at') }} as date) as start_month,
        min(start_at) as start_at,
        max(end_at) as end_at,
        max(amount) as discount_amount
    from discount
    where subscription_id is not null
      and coupon_id is not null
      and start_at is not null
    {{ dbt_utils.group_by(5) }}

),

subscription_discount_schedule as (

    select
        discount_dedupe.source_relation,
        discount_dedupe.subscription_id,
        discount_dedupe.customer_id,
        discount_dedupe.coupon_id,
        discount_dedupe.start_at,
        discount_dedupe.end_at,
        discount_dedupe.start_month,
        discount_dedupe.discount_amount,
        coupon.duration,
        coupon.duration_in_months,
        coupon.currency as coupon_currency
    from discount_dedupe
    left join coupon
      on discount_dedupe.source_relation = coupon.source_relation
      and discount_dedupe.coupon_id = coupon.coupon_id

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