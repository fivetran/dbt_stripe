{{ config(enabled=var('stripe__using_subscriptions', True)) }}

with mrr_by_item as (
    select *
    from {{ ref('stripe__subscription_item_mrr_report') }}

),

monthly_rollup as (
    select
        source_relation,
        subscription_month as recurring_rev_month,
        subscription_year as recurring_rev_year,
        currency,
        sum(current_month_mrr) as total_mrr
    from mrr_by_item
     {{ dbt_utils.group_by(4) }}

),

snapshots as (
    select
        source_relation,
        recurring_rev_month,
        recurring_rev_year,
        currency,
        total_mrr,
        total_mrr * 12 as total_arr,
        row_number() over (
            partition by source_relation, recurring_rev_year, currency
            order by recurring_rev_month desc
        ) as month_number
    from monthly_rollup

),

final as (
    select
        source_relation,
        recurring_rev_year,
        currency,
        round(total_arr, 2) as total_arr
    from snapshots
    where month_number = 1       -- last month in that year

)

select *
from final