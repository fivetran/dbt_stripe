{{ config(enabled=var('stripe__using_coupons', True)) }}

with stg_stripe__discount as (

    select *
    from {{ ref('stg_stripe__discount') }}

),

stg_stripe__coupon as (

    select *
    from {{ ref('stg_stripe__coupon') }}

),

discount_normalized as (

    select
        discount_id,
        subscription_id,
        customer_id,
        coupon_id,
        start_at,
        end_at,
        amount as discount_amount,
        type,
        invoice_id,
        invoice_item_id,
        promotion_code,
        coalesce(source_relation, '') as source_relation
    from stg_stripe__discount
    where subscription_id is not null
      and coupon_id is not null
      and start_at is not null

),

coupon_normalized as (

    select
        coupon_id,
        duration,
        duration_in_months,
        currency,
        valid,
        coalesce(source_relation, '') as source_relation
    from stg_stripe__coupon

),

/*
Aggressive coupon-based dedupe to avoid double counting event representations
(e.g., invoice_line_item + upcoming_invoice_line_item for same effective discount).

We collapse to a "subscription + coupon + start_month" episode and keep ONE effective
discount amount for that episode.

Using MAX(discount_amount) prevents double counting when duplicates exist.
*/
coupon_discount as (

    select
        discount_normalized.source_relation,
        discount_normalized.subscription_id,
        discount_normalized.customer_id,
        discount_normalized.coupon_id,
        cast({{ dbt.date_trunc('month', 'discount_normalized.start_at') }} as date) as start_month,
        min(discount_normalized.start_at) as start_at,
        max(discount_normalized.end_at) as end_at,
        max(discount_normalized.discount_amount) as discount_amount
    from discount_normalized
    {{ dbt_utils.group_by(5) }}

),

subscription_discount_schedule as (

    select
        coupon_discount.source_relation,
        coupon_discount.subscription_id,
        coupon_discount.customer_id,
        coupon_discount.coupon_id,
        coupon_discount.start_at,
        coupon_discount.end_at,
        coupon_discount.start_month,
        coupon_discount.discount_amount,
        coupon_normalized.duration,
        coupon_normalized.duration_in_months,
        coupon_normalized.currency as coupon_currency
    from coupon_discount
    left join coupon_normalized
      on coupon_discount.source_relation = coupon_normalized.source_relation
     and coupon_discount.coupon_id = coupon_normalized.coupon_id

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