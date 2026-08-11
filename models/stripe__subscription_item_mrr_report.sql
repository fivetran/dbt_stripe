{{ config(enabled=var('stripe__using_subscriptions', True) and var('stripe__using_invoices', True)) }}

{% if execute and flags.WHICH in ('run', 'build') %}

  {%- set first_month_query -%}
    select coalesce(
      min(
        cast(
          {{ dbt.date_trunc(
              'month',
              "coalesce(subscription_item.created_at, subscription.created_at)"
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

  {# dbt_utils.get_single_value returns a string, so cast it back to date #}
  {% set first_month_pre = dbt_utils.get_single_value(first_month_query) %}

  {% set first_month = "cast('" ~ first_month_pre ~ "' as date)" %}
  {% set last_month  = dbt.date_trunc('month', 'current_date') %}

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

    select *,
         row_number() over (partition by subscription_id {{ fivetran_utils.partition_by_source_relation(package_name='stripe') }}
             order by created_at desc) as rn
    from {{ ref('stg_stripe__subscription') }}
),

subscription_deduped as (

    select *
    from subscription
    where rn = 1
),

--deduping is necessary in cases where subscription_history table is used, multiple records can exist for the same subscription

price_plan as (

    select *
    from {{ ref('stg_stripe__price_plan') }}

),

-- Actual billed quantity per period; provides quantity history subscription_item lacks. Prorations excluded.
invoice_line_item as (

    select *
    from {{ ref('stg_stripe__invoice_line_item') }}
    where subscription_item_id is not null
        and not coalesce(proration, false)

),

{% if var('stripe__using_coupons', True) and var('stripe__using_subscription_discounts', True) %}
subscription_discount as (

    select *
    from {{ ref('int_stripe__subscription_discount') }}

),
{% endif %}


date_spine as (

    {{ dbt_utils.date_spine(
        datepart = "month",
        start_date = first_month,
        end_date = dbt.dateadd("month", 1, last_month)
    ) }}

),

-- Only keep month and year
date_dimensions as (

    select
        cast(date_month as date) as subscription_month,
        cast({{ dbt.date_trunc('year', 'date_month') }} as date) as subscription_year
    from date_spine

),

-- Anchor each billed quantity and unit amount to its period_start month, keeping the latest line per month.
-- Months the period spans beyond period_start are filled later by the carry-forward logic.
invoiced_quantity_by_month as (

    select
        invoice_line_item.source_relation,
        invoice_line_item.subscription_item_id,
        date_dimensions.subscription_month,
        invoice_line_item.quantity,
        invoice_line_item.unit_amount_excluding_tax,
        row_number() over (
            partition by
                invoice_line_item.source_relation,
                invoice_line_item.subscription_item_id,
                date_dimensions.subscription_month
            order by invoice_line_item.period_start desc
        ) as rn
    from invoice_line_item
    inner join date_dimensions
        on date_dimensions.subscription_month = cast({{ dbt.date_trunc('month', 'invoice_line_item.period_start') }} as date)

),

invoiced_quantity_deduped as (

    select
        source_relation,
        subscription_item_id,
        subscription_month,
        quantity,
        unit_amount_excluding_tax
    from invoiced_quantity_by_month
    where rn = 1

),

base as (

    select
        subscription_item.source_relation,
        subscription_item.subscription_item_id,
        subscription_item.subscription_id,
        subscription.customer_id,
        subscription.status as subscription_status,
        coalesce(subscription_item.created_at, subscription.created_at) as item_created_at,
        coalesce(subscription_item.current_period_start, subscription.current_period_start) as current_period_start,
        coalesce(subscription_item.current_period_end, subscription.current_period_end) as current_period_end,
        subscription_item.quantity as current_quantity,
        price_plan.product_id,
        price_plan.price_plan_id,
        price_plan.recurring_interval,
        price_plan.recurring_interval_count,
        price_plan.currency,
        price_plan.unit_amount
    from subscription_item
    left join subscription_deduped as subscription
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
        item_created_at,
        current_period_start,
        current_period_end,
        current_quantity,
        product_id,
        price_plan_id,
        recurring_interval,
        recurring_interval_count,
        currency,
        unit_amount
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
        min(cast({{ dbt.date_trunc('month', 'item_created_at') }} as date)) as first_active_month,
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

-- attach the invoiced quantity and unit amount to each month, then carry the most recent
-- invoiced values forward across any months missing an invoice (gap months)
item_month_invoiced as (

    select
        all_item_months.*,
        invoiced_quantity_deduped.quantity as invoiced_quantity,
        invoiced_quantity_deduped.unit_amount_excluding_tax as invoiced_unit_amount
    from all_item_months
    left join invoiced_quantity_deduped
        on all_item_months.source_relation = invoiced_quantity_deduped.source_relation
        and all_item_months.subscription_item_id = invoiced_quantity_deduped.subscription_item_id
        and all_item_months.subscription_month = invoiced_quantity_deduped.subscription_month

),

-- increment a group id each time an invoiced quantity appears; gap months inherit the prior group
item_month_grouped as (

    select
        *,
        sum(case when invoiced_quantity is not null then 1 else 0 end) over (
            partition by source_relation, subscription_item_id
            order by subscription_month
            rows between unbounded preceding and current row
        ) as invoiced_group
    from item_month_invoiced

),

-- within each group the single invoiced value carries forward to the gap months
item_month_carried as (

    select
        *,
        max(invoiced_quantity) over (
            partition by source_relation, subscription_item_id, invoiced_group
        ) as carried_quantity,
        max(invoiced_unit_amount) over (
            partition by source_relation, subscription_item_id, invoiced_group
        ) as carried_unit_amount
    from item_month_grouped

),

-- Join back to normalized to determine if subscription was active in each month
item_months as (

    select
        item_month_carried.source_relation,
        item_month_carried.subscription_item_id,
        item_month_carried.subscription_id,
        item_month_carried.customer_id,
        item_month_carried.product_id,
        item_month_carried.price_plan_id,
        item_month_carried.subscription_status,
        item_month_carried.currency,
        item_month_carried.subscription_year,
        item_month_carried.subscription_month,
        -- set once to stay DRY; reused in the mrr calculation below
        {% set effective_quantity %}
            case
                when item_month_carried.subscription_month = cast({{ last_month }} as date)
                    then coalesce(normalized.current_quantity, 1)
                else coalesce(item_month_carried.carried_quantity, normalized.current_quantity, 1)
            end
        {% endset %}
        {% set effective_unit_amount %}
            case
                when item_month_carried.subscription_month = cast({{ last_month }} as date)
                    then normalized.unit_amount
                else coalesce(item_month_carried.carried_unit_amount, normalized.unit_amount)
            end
        {% endset %}
        {% set effective_amount = "(" ~ effective_unit_amount ~ ") * (" ~ effective_quantity ~ ")" %}
        -- current month uses the live price and quantity, history uses the carried-forward invoiced values
        coalesce(
            case
                when lower(normalized.recurring_interval) = 'week' then
                    {{ dbt_utils.safe_divide(
                        effective_amount ~ " * " ~ dbt_utils.safe_divide('52', '12'),
                        "coalesce(normalized.recurring_interval_count, 1)"
                    ) }}

                when lower(normalized.recurring_interval) = 'month' then
                    {{ dbt_utils.safe_divide(
                        effective_amount,
                        "coalesce(normalized.recurring_interval_count, 1)"
                    ) }}

                when lower(normalized.recurring_interval) = 'year' then
                    {{ dbt_utils.safe_divide(
                        effective_amount,
                        "12 * coalesce(normalized.recurring_interval_count, 1)"
                    ) }}

                else null
            end, 0) as mrr
    from item_month_carried
    left join normalized
        on item_month_carried.source_relation = normalized.source_relation
        and item_month_carried.subscription_item_id = normalized.subscription_item_id
        and item_month_carried.price_plan_id = normalized.price_plan_id
        and item_month_carried.subscription_month >= cast({{ dbt.date_trunc('month', 'normalized.item_created_at') }} as date)
        and item_month_carried.subscription_month < cast({{ dbt.date_trunc('month', 'normalized.current_period_end') }} as date)

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

{% if var('stripe__using_coupons', True) and var('stripe__using_subscription_discounts', True) %}
subscription_month_discount_amount as (

    select
        subscription_month_contracted.source_relation,
        subscription_month_contracted.subscription_id,
        subscription_month_contracted.subscription_month,
        subscription_month_contracted.currency,
        subscription_month_contracted.subscription_month_contracted_mrr,
        sum(coalesce(cast(subscription_discount.amount_off as {{ dbt.type_numeric() }}), 0)) as amount_off,
        max(coalesce(cast(subscription_discount.percent_off as {{ dbt.type_numeric() }}), 0)) as percent_off
    from subscription_month_contracted
    left join subscription_discount
        on subscription_month_contracted.source_relation = subscription_discount.source_relation
        and subscription_month_contracted.subscription_id = subscription_discount.subscription_id
        and subscription_month_contracted.subscription_month >= subscription_discount.start_month
        and (
            subscription_discount.end_month is null
            or subscription_month_contracted.subscription_month < subscription_discount.end_month
        )
        {{ dbt_utils.group_by(5) }}
),

subscription_month_discount_mrr as (

    select
        subscription_month_discount_amount.source_relation,
        subscription_month_discount_amount.subscription_id,
        subscription_month_discount_amount.subscription_month,
        subscription_month_discount_amount.amount_off,
        subscription_month_discount_amount.percent_off,

        -- Monthly discount from amount_off (spread across billing cycle)
        {{ dbt_utils.safe_divide(
            "subscription_month_discount_amount.amount_off",
            "coalesce(subscription_billing_cycle.subscription_cycle_months, 1)"
        ) }} as amount_off_monthly_discount,

        -- Monthly discount from percent_off (applies directly to monthly contracted MRR)
        (subscription_month_discount_amount.subscription_month_contracted_mrr
            * {{ dbt_utils.safe_divide("subscription_month_discount_amount.percent_off", "100") }}
        ) as percent_off_monthly_discount,

        -- Total monthly discount to allocate to items
        (coalesce({{ dbt_utils.safe_divide("subscription_month_discount_amount.amount_off",
                    "coalesce(subscription_billing_cycle.subscription_cycle_months, 1)") }}, 0)
        + coalesce((subscription_month_discount_amount.subscription_month_contracted_mrr
                    * {{ dbt_utils.safe_divide("subscription_month_discount_amount.percent_off", "100") }}), 0)
        ) as subscription_month_discount_mrr

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

        -- applied discount at item grain (monthly)
        {% if var('stripe__using_coupons', True) and var('stripe__using_subscription_discounts', True) %}
        (
            coalesce(subscription_month_discount_mrr.subscription_month_discount_mrr, 0)
            * {{ dbt_utils.safe_divide(
                "item_mrr_by_month.month_mrr",
                "subscription_month_contracted.subscription_month_contracted_mrr"
            ) }}
        ) as month_discount_applied,
        {% else %}
        0 as month_discount_applied,
        {% endif %}

        -- net / invoiced monthly MRR at item grain
        {% if var('stripe__using_coupons', True) and var('stripe__using_subscription_discounts', True) %}
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
        {% else %}
        item_mrr_by_month.month_mrr as month_billed_mrr
        {% endif %}

    from item_mrr_by_month
    left join subscription_month_contracted
        on item_mrr_by_month.source_relation = subscription_month_contracted.source_relation
        and item_mrr_by_month.subscription_id = subscription_month_contracted.subscription_id
        and item_mrr_by_month.currency = subscription_month_contracted.currency
        and item_mrr_by_month.subscription_month = subscription_month_contracted.subscription_month
    {% if var('stripe__using_coupons', True) and var('stripe__using_subscription_discounts', True) %}
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