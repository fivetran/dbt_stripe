with subscription as (
    select * from {{ ref('stripe__subscription_details') }}
),
subscription_item as (
    select * from {{ var('subscription_item') }}
),
price as (
    select * from {{ var('price') }}
)

select 
    subscription.subscription_id,
    sum(subscription_item.quantity * price.unit_amount) as total
from subscription
left join subscription_item
    on subscription.subscription_id = subscription_item.subscription_id
left join price
    on subscription_item.plan_id = price.id
where 
    subscription.status IN ('active', 'past_due')
group by subscription.subscription_id