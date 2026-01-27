{{ config(enabled=var('stripe__using_subscriptions', True)) }}

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

{% if var('stripe__using_coupons', True) %}
subscription_discount as (

    select *
    from {{ ref('int_stripe__subscription_discount') }}

),
{% endif %}


date_spine as (

    {{ dbt_utils.date_spine(
        datepart = "month",
        start_date = first_month,
        end_date = dbt.dateadd("month", 4, last_month)
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
        price_plan.price_plan_id,
        price_plan.recurring_interval,
        price_plan.recurring_interval_count,
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
        price_plan_id,
        recurring_interval,
        recurring_interval_count,
        currency,
        amount,
        case
            when lower(recurring_interval) = 'week' then
                {{ dbt_utils.safe_divide(
                    "amount * " ~ dbt_utils.safe_divide('52', '12'),
                    "coalesce(recurring_interval_count, 1)"
                ) }}

            when lower(recurring_interval) = 'month' then
                {{ dbt_utils.safe_divide(
                    "amount",
                    "coalesce(recurring_interval_count, 1)"
                ) }}

            when lower(recurring_interval) = 'year' then
                {{ dbt_utils.safe_divide(
                    "amount",
                    "12 * coalesce(recurring_interval_count, 1)"
                ) }}

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
        price_plan_id,
        subscription_status,
        currency,
        min(cast({{ dbt.date_trunc('month', 'current_period_start') }} as date)) as first_active_month,
        cast({{ dbt.dateadd('month', 3, 'max(cast(' ~ dbt.date_trunc('month', 'current_period_end') ~ ' as date))') }} as date) as last_month_to_track
    from normalized
    {{ dbt_utils.group_by(8) }}

),

-- Create all possible month combinations for each subscription item
all_item_months as (

    select
        subscription_item_periods.source_relation,
        subscription_item_periods.subscription_item_id,
        subscription_item_periods.subscription_id,
        subscription_item_periods.customer_id,
        subscription_item_periods.product_id,
        subscription_item_periods.price_plan_id,
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
        all_item_months.price_plan_id,
        all_item_months.subscription_status,
        all_item_months.currency,
        all_item_months.subscription_year,
        all_item_months.subscription_month,
        coalesce(normalized.mrr, 0) as mrr
    from all_item_months
    left join normalized
        on all_item_months.source_relation = normalized.source_relation
        and all_item_months.subscription_item_id = normalized.subscription_item_id
        and all_item_months.price_plan_id = normalized.price_plan_id
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
        price_plan_id,
        subscription_status,
        currency,
        subscription_year,
        subscription_month,
        sum(mrr) as month_mrr
    from item_months
    {{ dbt_utils.group_by(10) }}

),

subscription_billing_cycle as (

    select
        normalized.source_relation,
        normalized.subscription_id,
        max(
            case
                when normalized.recurring_interval = 'week' then
                    coalesce(normalized.recurring_interval_count, 1) * {{ dbt_utils.safe_divide('52', '12') }}
                when normalized.recurring_interval = 'month' then
                    coalesce(normalized.recurring_interval_count, 1)
                when normalized.recurring_interval = 'year' then
                    12 * coalesce(normalized.recurring_interval_count, 1)
                else null
            end
        ) as subscription_cycle_months
    from normalized
    {{ dbt_utils.group_by(2) }}

),

subscription_month_contracted as (

    select
        item_mrr_by_month.source_relation,
        item_mrr_by_month.subscription_id,
        item_mrr_by_month.currency,
        item_mrr_by_month.subscription_month,
        sum(item_mrr_by_month.month_mrr) as subscription_month_contracted_mrr
    from item_mrr_by_month
    {{ dbt_utils.group_by(4) }}

),

{% if var('stripe__using_coupons', True) %}
subscription_month_discount_amount as (

    select
        subscription_month_contracted.source_relation,
        subscription_month_contracted.subscription_id,
        subscription_month_contracted.subscription_month,
        sum(coalesce(cast(nullif(cast(subscription_discount.discount_amount as {{ dbt.type_string() }}), '') as {{ dbt.type_numeric() }} ), 0)) as discount_amount
    from subscription_month_contracted
    left join subscription_discount
        on subscription_month_contracted.source_relation = subscription_discount.source_relation
        and subscription_month_contracted.subscription_id = subscription_discount.subscription_id
        and subscription_month_contracted.subscription_month >= subscription_discount.start_month
        and (
            subscription_discount.end_month is null
            or subscription_month_contracted.subscription_month < subscription_discount.end_month
        )
        {{ dbt_utils.group_by(3) }}
),

subscription_month_discount_mrr as (

    select
        subscription_month_discount_amount.source_relation,
        subscription_month_discount_amount.subscription_id,
        subscription_month_discount_amount.subscription_month,
        subscription_month_discount_amount.discount_amount,

        {{ dbt_utils.safe_divide(
            "subscription_month_discount_amount.discount_amount",
            "coalesce(subscription_billing_cycle.subscription_cycle_months, 1)"
        ) }} as subscription_month_discount_mrr

    from subscription_month_discount_amount
    left join subscription_billing_cycle
        on subscription_month_discount_amount.source_relation = subscription_billing_cycle.source_relation
        and subscription_month_discount_amount.subscription_id = subscription_billing_cycle.subscription_id

),
{% endif %}

item_mrr_with_discounts as (

    select
        item_mrr_by_month.source_relation,
        item_mrr_by_month.subscription_item_id,
        item_mrr_by_month.subscription_id,
        item_mrr_by_month.customer_id,
        item_mrr_by_month.product_id,
        item_mrr_by_month.price_plan_id,
        item_mrr_by_month.subscription_status,
        item_mrr_by_month.currency,
        item_mrr_by_month.subscription_year,
        item_mrr_by_month.subscription_month,
        item_mrr_by_month.month_mrr as month_contract_mrr,

        -- allocation share (by contracted monthly MRR)
        {{ dbt_utils.safe_divide(
            "item_mrr_by_month.month_mrr",
            "subscription_month_contracted.subscription_month_contracted_mrr"
        ) }} as discount_allocation_share,

        -- allocated discount at item grain (monthly)
        (
            coalesce(subscription_month_discount_mrr.subscription_month_discount_mrr, 0)
            * {{ dbt_utils.safe_divide(
                "item_mrr_by_month.month_mrr",
                "subscription_month_contracted.subscription_month_contracted_mrr"
            ) }}
        ) as month_discount_applied,

        -- net / invoiced monthly MRR at item grain
        (
            item_mrr_by_month.month_mrr
            - (
                coalesce(subscription_month_discount_mrr.subscription_month_discount_mrr, 0)
                * {{ dbt_utils.safe_divide(
                    "item_mrr_by_month.month_mrr",
                    "subscription_month_contracted.subscription_month_contracted_mrr"
                    ) }}
              )
        ) as month_billed_mrr

    from item_mrr_by_month
    left join subscription_month_contracted
        on item_mrr_by_month.source_relation = subscription_month_contracted.source_relation
        and item_mrr_by_month.subscription_id = subscription_month_contracted.subscription_id
        and item_mrr_by_month.currency = subscription_month_contracted.currency
        and item_mrr_by_month.subscription_month = subscription_month_contracted.subscription_month
    {% if var('stripe__using_coupons', True) %}
    left join subscription_month_discount_mrr
        on item_mrr_by_month.source_relation = subscription_month_discount_mrr.source_relation
        and item_mrr_by_month.subscription_id = subscription_month_discount_mrr.subscription_id
        and item_mrr_by_month.subscription_month = subscription_month_discount_mrr.subscription_month
    {% endif %}

),

lagged as (

    select
        item_mrr_with_discounts.source_relation,
        item_mrr_with_discounts.subscription_item_id,
        item_mrr_with_discounts.subscription_id,
        item_mrr_with_discounts.customer_id,
        item_mrr_with_discounts.product_id,
        item_mrr_with_discounts.price_plan_id,
        item_mrr_with_discounts.subscription_status,
        item_mrr_with_discounts.currency,
        item_mrr_with_discounts.subscription_month,
        item_mrr_with_discounts.subscription_year,
        item_mrr_with_discounts.month_contract_mrr,
        item_mrr_with_discounts.month_discount_applied,
        item_mrr_with_discounts.month_billed_mrr,
        lag(item_mrr_with_discounts.month_contract_mrr) over (
            partition by
                item_mrr_with_discounts.source_relation,
                item_mrr_with_discounts.subscription_item_id,
                item_mrr_with_discounts.price_plan_id
            order by
                item_mrr_with_discounts.subscription_year,
                item_mrr_with_discounts.subscription_month
        ) as prior_month_contract_mrr,
        row_number() over (
            partition by
                item_mrr_with_discounts.source_relation,
                item_mrr_with_discounts.subscription_item_id,
                item_mrr_with_discounts.price_plan_id
            order by
                item_mrr_with_discounts.subscription_year,
                item_mrr_with_discounts.subscription_month
        ) as item_month_number
    from item_mrr_with_discounts

),

classified as (

    select
        *,
        case
            when prior_month_contract_mrr is null 
                and month_contract_mrr > 0
                then 'new'

            when month_contract_mrr > prior_month_contract_mrr
                then 'expansion'

            when prior_month_contract_mrr > month_contract_mrr
                and month_contract_mrr > 0
                then 'contraction'

            when (month_contract_mrr = 0 or month_contract_mrr is null)
                and prior_month_contract_mrr > 0
                then 'churned'

            when prior_month_contract_mrr = 0
                and month_contract_mrr > 0
                and item_month_number >= 3
                then 'reactivation'

            when month_contract_mrr = prior_month_contract_mrr
                then 'unchanged'

            else 'unknown'
        end as contract_mrr_type
    from lagged
)

select *
from classified
