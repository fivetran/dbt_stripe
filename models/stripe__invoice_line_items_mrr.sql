{% if var('using_subscriptions', True) %}
WITH invoice_line_item as (

    select *
    from {{ ref('stripe__invoice_line_items') }}

)

select
    invoice_id,
    invoice_created_at,
    tax,
    invoice_line_item_id,
    line_item_desc,
    line_item_amount,
    period_start,
    period_end,
    estimated_service_start,
    customer_description,
    customer_email,
    customer_id,
    proration,
    subscription_duration_ratio,
    estimated_full_service_period,
    prorated_service_period,
    estimated_full_service_period / prorated_service_period as prorate_factor,
    (line_item_amount - tax) * subscription_duration_ratio * (estimated_full_service_period / prorated_service_period) as mrr,
    subscription_id,
    subscription_start_date,
    subscription_ended_at,
    plan_id,
    plan_interval,
    plan_interval_count

from invoice_line_item
where
    subscription_id IS NOT NULL AND 
    prorated_service_period <> 0 AND
    status IN ('open', 'paid') AND
    amount_due > 0

{% endif %}
