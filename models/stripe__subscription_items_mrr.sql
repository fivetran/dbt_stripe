with subscription as (
    select * from {{ ref('stripe__subscription_details') }}
),
subscription_item as (
    select * from {{ var('subscription_item') }}
),
subscription_discounts as (
    select * from {{ ref('stripe__subscription_discounts') }}
),
price as (
    select * from {{ var('price') }}
),
product as (
    select * from {{ var('product') }}
)

select 
    subscription.subscription_id,
    subscription_item.quantity * COALESCE(price.unit_amount::FLOAT,price.unit_amount_decimal::FLOAT) as line_item_amount,
    coalesce(discount_factor, 1) as discount_factor,
    subscription_item.quantity * COALESCE(price.unit_amount::FLOAT,price.unit_amount_decimal::FLOAT) * coalesce(discount_factor, 1) as line_item_amount_with_discount,
    customer_description,
    customer_email,
    customer_id,
    case recurring_interval
        when 'week' then recurring_interval_count * 4
        when 'month' then recurring_interval_count
        when 'year' then recurring_interval_count / 12.0
    end as subscription_duration_ratio,
    case
        when subscription.status NOT IN ('active', 'past_due') THEN 0 ELSE
    subscription_item.quantity * COALESCE(price.unit_amount::FLOAT,price.unit_amount_decimal::FLOAT) * coalesce(discount_factor, 1) * case recurring_interval
        when 'week' then recurring_interval_count * 4
        when 'month' then (1::FLOAT/recurring_interval_count::FLOAT)
        when 'year' then recurring_interval_count / 12.0
    end 
    end as mrr,
    case
        when subscription.status NOT IN ('active', 'past_due') THEN 0 ELSE
    subscription_item.quantity * COALESCE(price.brl_unit_amount::FLOAT,price.brl_unit_amount_decimal::FLOAT) * coalesce(discount_factor, 1) * case recurring_interval
        when 'week' then recurring_interval_count * 4
        when 'month' then (1::FLOAT/recurring_interval_count::FLOAT)
        when 'year' then recurring_interval_count / 12.0
    end 
    end as brl_mrr,
    product.id as product_id,
    subscription.stripe_account
from subscription
left join subscription_item
    on subscription.subscription_id = subscription_item.subscription_id
left join subscription_discounts
    on subscription.subscription_id = subscription_discounts.subscription_id
left join price
    on subscription_item.plan_id = price.id
left join product
    on price.product_id = product.id

