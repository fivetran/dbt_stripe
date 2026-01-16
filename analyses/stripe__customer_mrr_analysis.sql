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
        sum(month_contract_mrr) as month_contract_mrr,
        sum(month_discount_applied) as month_discount_applied,
        sum(month_billed_mrr) as month_billed_mrr
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
        month_contract_mrr,
        month_discount_applied,
        month_billed_mrr,
        lag(month_contract_mrr) over (
            partition by source_relation, customer_id, currency
            order by subscription_year, subscription_month
        ) as prior_month_contract_mrr,
        lag(month_billed_mrr) over (
            partition by source_relation, customer_id, currency
            order by subscription_year, subscription_month
        ) as prior_month_billed_mrr
    from customer_mrr
)

select
    *,
    case
        when prior_month_contract_mrr is null
             and month_contract_mrr > 0 then 'new'
        when month_contract_mrr > prior_month_contract_mrr then 'expansion'
        when prior_month_contract_mrr > month_contract_mrr
             and month_contract_mrr > 0 then 'contraction'
        when (month_contract_mrr = 0 or month_contract_mrr is null)
             and prior_month_contract_mrr > 0 then 'churned'
        when prior_month_contract_mrr = 0
             and month_contract_mrr > 0 then 'reactivation'
        when month_contract_mrr = prior_month_contract_mrr then 'unchanged'
        else 'unknown'
    end as customer_contract_mrr_type,
    case
        when prior_month_billed_mrr is null
             and month_billed_mrr > 0 then 'new'
        when month_billed_mrr > prior_month_billed_mrr then 'expansion'
        when prior_month_billed_mrr > month_billed_mrr
             and month_billed_mrr > 0 then 'contraction'
        when (month_billed_mrr = 0 or month_billed_mrr is null)
             and prior_month_billed_mrr > 0 then 'churned'
        when prior_month_billed_mrr = 0
             and month_billed_mrr > 0 then 'reactivation'
        when month_billed_mrr = prior_month_billed_mrr then 'unchanged'
        else 'unknown'
    end as customer_billed_mrr_type
from customer_mrr_lagged