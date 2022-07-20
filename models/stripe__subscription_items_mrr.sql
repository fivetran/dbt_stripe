with subscription as (
    select * from {{ ref('stripe__subscription_details') }}
),
subscription_item as (
    select * from {{ var('subscription_item') }}
),
price as (
    select * from {{ var('price') }}
),
product as (
    select * from {{ var('product') }}
)

select 
    null as invoice_id,
    current_period_end invoice_created_at,
    0 as tax,
    null as invoice_line_item_id,
    product.name as line_item_desc,
    subscription_item.quantity * price.unit_amount as line_item_amount,
    1 as discount_factor,
    subscription_item.quantity * price.unit_amount as line_item_amount_with_discount,
    current_period_start as period_start,
    current_period_end as period_end,
    current_period_start as estimated_service_start,
    customer_description,
    customer_email,
    customer_id,
    false as proration ,
    case recurring_interval
        when 'week' then recurring_interval_count * 4
        when 'month' then recurring_interval_count
        when 'year' then recurring_interval_count / 12.0
    end as subscription_duration_ratio,
    extract(epoch from (current_period_end - current_period_start)) as estimated_full_service_period,
    extract(epoch from (current_period_end - current_period_start)) as prorated_service_period,
    1 as prorate_factor,
    subscription_item.quantity * price.unit_amount * case recurring_interval
        when 'week' then recurring_interval_count * 4
        when 'month' then recurring_interval_count
        when 'year' then recurring_interval_count / 12.0
    end as mrr,
    subscription.subscription_id,
    subscription.start_date,
    subscription.ended_at,
    plan_id,
    recurring_interval as plan_interval,
    recurring_interval_count as plan_interval_count

from subscription
left join subscription_item
    on subscription.subscription_id = subscription_item.subscription_id
left join price
    on subscription_item.plan_id = price.id
left join product
    on product.id = price.product_id
where 
    subscription.status IN ('active', 'past_due')
