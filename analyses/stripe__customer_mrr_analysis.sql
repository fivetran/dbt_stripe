{{ config(enabled=var('stripe__using_subscriptions', True)) }}

with item_mrr as (
    select *
    from {{ ref('stripe__subscription_item_mrr_report') }}
),

customer_mrr as (
    select
        source_relation,
        customer_id,
        subscription_year,
        subscription_month,
        currency,
        sum(month_mrr)  as month_mrr
    from item_mrr
    group by
      1,2,3,4,5
),

customer_mrr_lagged as (
    select
        source_relation,
        customer_id,
        subscription_year,
        subscription_month,
        currency,
        month_mrr,
        lag(month_mrr) over (
            partition by source_relation, customer_id, currency
            order by subscription_year, subscription_month
        ) as prior_month_mrr
    from customer_mrr
)

select
    *,
    case
        when prior_month_mrr is null
             and month_mrr > 0 then 'new'
        when month_mrr > prior_month_mrr then 'expansion'
        when prior_month_mrr > month_mrr
             and month_mrr > 0 then 'contraction'
        when (month_mrr = 0 or month_mrr is null)
             and prior_month_mrr > 0 then 'churned'
        when prior_month_mrr = 0
             and month_mrr > 0 then 'reactivation'
        when month_mrr = prior_month_mrr then 'unchanged'
        else 'unknown'
    end as customer_mrr_type
from customer_mrr_lagged