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
        sum(current_month_mrr)  as current_month_mrr,
        sum(previous_month_mrr) as previous_month_mrr
    from item_mrr
    group by
      1,2,3,4,5
)

select
    *,
    case
        when previous_month_mrr is null 
             and current_month_mrr > 0 then 'new'
        when current_month_mrr > previous_month_mrr then 'expansion'
        when previous_month_mrr > current_month_mrr
             and current_month_mrr > 0 then 'contraction'
        when (current_month_mrr = 0 or current_month_mrr is null)
             and previous_month_mrr > 0 then 'churned'
        when previous_month_mrr = 0
             and current_month_mrr > 0 then 'reactivation'
        when current_month_mrr = previous_month_mrr then 'unchanged'
        else 'unknown'
    end as customer_mrr_type
from customer_mrr