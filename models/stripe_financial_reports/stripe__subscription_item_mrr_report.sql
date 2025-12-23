{{ config(enabled=var('stripe__using_subscriptions', True)) }}

{% set post_churn_months = var('stripe__mrr_post_churn_months', 3) %}

{% if execute and flags.WHICH in ('run', 'build') %}

  {%- set first_month_query -%}
    select coalesce(
      min(
        cast(
          {{ dbt.date_trunc(
              'month',
              "coalesce(subscription_item.current_period_start, subscription.current_period_start)"
          ) }} as date
        )
      ),
      cast({{ dbt.dateadd('month', -1, 'current_date') }} as date)
    ) as min_month
    from {{ ref('stg_stripe__subscription_item') }} as subscription_item
    left join {{ ref('stg_stripe__subscription') }} as subscription
      on subscription_item.subscription_id = subscription.subscription_id
      and subscription_item.source_relation = subscription.source_relation
  {%- endset -%}

  {%- set last_month_query -%}
    select coalesce(
      max(
        cast(
          {{ dbt.date_trunc(
              'month',
              "coalesce(subscription_item.current_period_end, subscription.current_period_end)"
          ) }} as date
        )
      ),
      cast({{ dbt.date_trunc('month', 'current_date') }} as date)
    ) as max_month
    from {{ ref('stg_stripe__subscription_item') }} as subscription_item
    left join {{ ref('stg_stripe__subscription') }} as subscription
      on subscription_item.subscription_id = subscription.subscription_id
      and subscription_item.source_relation = subscription.source_relation
  {%- endset -%}

  {# dbt_utils.get_single_value returns a string, so cast it back to date #}
  {% set first_month_pre = dbt_utils.get_single_value(first_month_query) %}
  {% set last_month_pre  = dbt_utils.get_single_value(last_month_query) %}

  {% set first_month = "cast('" ~ first_month_pre ~ "' as date)" %}
  {% set last_month  = "cast('"  ~ last_month_pre  ~ "' as date)" %}

{% else %}

  {# Fallback for compile / docs / parsing #}
  {% set first_month = dbt.dateadd('month', -1, 'current_date') %}
  {% set last_month  = dbt.date_trunc('month', 'current_date') %}

{% endif %}

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

    {{ dbt_utils.date_spine(
        datepart = "month",
        start_date = first_month,
        end_date = dbt.dateadd("month", post_churn_months + 1, last_month)
    ) }}

),

-- Only keep month and year
date_dimensions as (

    select
        cast(date_month as date) as subscription_month,
        cast({{ dbt.date_trunc('year', 'date_month') }} as date) as subscription_year
    from date_spine

),

base as (

    select
        subscription_item.source_relation,
        subscription_item.subscription_item_id,
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
        on cast(subscription_item.plan_id as {{ dbt.type_string() }}) = cast(price_plan.price_plan_id as {{ dbt.type_string() }})
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

-- Get distinct subscription items with their earliest and latest periods
-- Extend the timeline 3 months past the last active period to track churn
subscription_item_periods as (

    select
        source_relation,
        subscription_item_id,
        subscription_id,
        customer_id,
        product_id,
        subscription_status,
        currency,
        min(cast({{ dbt.date_trunc('month', 'current_period_start') }} as date)) as first_active_month,
        cast({{ dbt.dateadd('month', 3, 'max(cast(' ~ dbt.date_trunc('month', 'current_period_end') ~ ' as date))') }} as date) as last_month_to_track
    from normalized
    {{ dbt_utils.group_by(7) }}

),

-- Create all possible month combinations for each subscription item
all_item_months as (

    select
        subscription_item_periods.source_relation,
        subscription_item_periods.subscription_item_id,
        subscription_item_periods.subscription_id,
        subscription_item_periods.customer_id,
        subscription_item_periods.product_id,
        subscription_item_periods.subscription_status,
        subscription_item_periods.currency,
        date_dimensions.subscription_year,
        date_dimensions.subscription_month
    from subscription_item_periods
    cross join date_dimensions
    where date_dimensions.subscription_month >= subscription_item_periods.first_active_month
        and date_dimensions.subscription_month < subscription_item_periods.last_month_to_track

),

-- Join back to normalized to determine if subscription was active in each month
item_months as (

    select
        all_item_months.source_relation,
        all_item_months.subscription_item_id,
        all_item_months.subscription_id,
        all_item_months.customer_id,
        all_item_months.product_id,
        all_item_months.subscription_status,
        all_item_months.currency,
        all_item_months.subscription_year,
        all_item_months.subscription_month,
        coalesce(normalized.mrr, 0) as mrr
    from all_item_months
    left join normalized
        on all_item_months.source_relation = normalized.source_relation
        and all_item_months.subscription_item_id = normalized.subscription_item_id
        and all_item_months.subscription_month >= cast({{ dbt.date_trunc('month', 'normalized.current_period_start') }} as date)
        and all_item_months.subscription_month < cast({{ dbt.date_trunc('month', 'normalized.current_period_end') }} as date)

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
        sum(mrr) as month_mrr
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
        month_mrr,
        lag(month_mrr) over (
            partition by source_relation, subscription_item_id
            order by subscription_year, subscription_month
        ) as prior_month_mrr,
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
            when prior_month_mrr is null 
                 and month_mrr > 0
                then 'new'

            when month_mrr > prior_month_mrr
                then 'expansion'

            when prior_month_mrr > month_mrr
                 and month_mrr > 0
                then 'contraction'

            when (month_mrr = 0 or month_mrr is null)
                 and prior_month_mrr > 0
                then 'churned'

            when prior_month_mrr = 0
                 and month_mrr > 0
                 and item_month_number >= 3
                then 'reactivation'

            when month_mrr = prior_month_mrr
                then 'unchanged'

            else 'unknown'
        end as mrr_type
    from lagged
)

select *
from classified
