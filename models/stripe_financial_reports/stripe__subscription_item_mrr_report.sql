{{ config(enabled=var('stripe__using_subscriptions', True)) }}

with subscription_item as (

    select *
    from {{ ref('stg_stripe__subscription_item') }}


),

subscription as (

    select *
    from {{ ref('stg_stripe__subscription') }}

),


price_plan as (

    select *
    from {{ ref('stg_stripe__price_plan') }}

),

date_spine as (
    
    select *
    from {{ ref('int_stripe__date_spine') }}

),

base as (

    select
        subscription_item.source_relation,
        subscription_item.subscription_item_id as subscription_item_id,
        subscription_item.subscription_id,
        subscription.customer_id,
        subscription.status as subscription_status,
        coalesce(subscription_item.current_period_start, subscription.current_period_start) as current_period_start,
        coalesce(subscription_item.current_period_end, subscription.current_period_end) as current_period_end,
        subscription_item.quantity,
        price_plan.product_id,
        price_plan.recurring_interval,
        price_plan.currency,
        {{ convert_values('price_plan.unit_amount * coalesce(subscription_item.quantity, 1)', alias='amount') }}
    from subscription_item
    left join subscription
        on subscription_item.subscription_id = subscription.subscription_id
        and subscription_item.source_relation = subscription.source_relation
    left join price_plan
        on subscription_item.plan_id = price_plan.price_plan_id
        and subscription_item.source_relation = price_plan.source_relation

),

normalized as (
    select
        source_relation,
        subscription_item_id,
        subscription_id,
        customer_id,
        subscription_status,
        current_period_start,
        current_period_end,
        product_id,
        recurring_interval,
        currency,
        amount,
        case
            when recurring_interval = 'month' then amount
            when recurring_interval = 'year' then amount / 12
            else null
        end as mrr
    from base

),

item_months as (

    select
        normalized.source_relation,
        normalized.subscription_item_id,
        normalized.subscription_id,
        normalized.customer_id,
        normalized.product_id,
        normalized.subscription_status,
        normalized.currency,
        date_spine.date_year as subscription_year,
        date_spine.date_month as subscription_month,
        normalized.mrr
    from normalized
    join date_spine
        on date_spine.date_month >=  cast({{ dbt.date_trunc('month', 'normalized.current_period_start') }} as date)
       and date_spine.date_month <  cast({{ dbt.date_trunc('month', 'normalized.current_period_end') }} as date)

),

item_mrr_by_month as (

    select
        source_relation,
        subscription_item_id,
        subscription_id,
        customer_id,
        product_id,
        subscription_status,
        currency,
        subscription_year,
        subscription_month,
        sum(mrr) as current_month_mrr
    from item_months
    {{ dbt_utils.group_by(9) }}

),

lagged as (

    select
        source_relation,
        subscription_item_id,
        subscription_id,
        customer_id,
        product_id,
        subscription_status,
        currency,
        subscription_month,
        subscription_year,
        current_month_mrr,
        lag(current_month_mrr) over (
            partition by source_relation, subscription_item_id
            order by subscription_year, subscription_month
        ) as previous_month_mrr,
        row_number() over (
            partition by source_relation, subscription_item_id
            order by subscription_year, subscription_month
        ) as item_month_number
    from item_mrr_by_month

),

classified as (

    select
        *,
        case
            when previous_month_mrr is null 
                 and current_month_mrr > 0
                then 'new'

            when current_month_mrr > previous_month_mrr
                then 'expansion'

            when previous_month_mrr > current_month_mrr
                 and current_month_mrr > 0
                then 'contraction'

            when (current_month_mrr = 0 or current_month_mrr is null)
                 and previous_month_mrr > 0
                then 'churned'

            when (previous_month_mrr = 0 and current_month_mrr > 0 
                and item_month_number >= 3) 
                then 'reactivation'

            when current_month_mrr = previous_month_mrr
                then 'unchanged'

            else 'unknown'
        end as mrr_type
    from lagged
)


select *
from classified