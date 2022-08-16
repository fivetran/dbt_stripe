with subscription_discounts as (
    select * from {{ ref('int_stripe__subscription_discounts') }}
),
subscription_totals as (
    select * from {{ ref('int_stripe__subscription_totals') }}
)

select 
    subscription_totals.subscription_id,
    total,
    coalesce(discounts, 0) as discounts,
    (total - coalesce(discounts, 0))::decimal / total as discount_factor
from subscription_totals
left join subscription_discounts 
on subscription_totals.subscription_id = subscription_discounts.subscription_id
where total > 0
