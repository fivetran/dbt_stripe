{{ config(enabled=var('stripe__using_invoices', True)) }}

with invoice as (

    select *
    from {{ var('invoice') }}  

), charge as (

    select *
    from {{ var('charge') }}  

), invoice_line_item as (

    select *
    from {{ var('invoice_line_item') }}  

), customer as (

    select *
    from {{ var('customer') }}  

{% if var('stripe__using_subscriptions', True) %}

), subscription as (

    select *
    from {{ var('subscription') }}  

), pricing as (

    select *
    from {{ var('pricing') }}  

{% endif %}
)

select 
    invoice.invoice_id,
    invoice.number,
    invoice.created_at as invoice_created_at,
    invoice.status,
    invoice.due_date,
    invoice.currency,
    invoice.amount_due,
    invoice.subtotal,
    invoice.tax,
    invoice.total,
    invoice.amount_paid,
    invoice.amount_remaining,
    invoice.attempt_count,
    invoice.description as invoice_memo,
    invoice_line_item.unique_id  as invoice_line_item_id,
    invoice_line_item.description as line_item_desc,
    invoice_line_item.amount as line_item_amount,
    invoice_line_item.quantity,
    invoice_line_item.period_start,
    invoice_line_item.period_end,
    charge.balance_transaction_id,
    charge.amount as charge_amount, 
    charge.status as charge_status,
    charge.created_at as charge_created_at,
    customer.description as customer_description,
    customer.email as customer_email,
    customer.customer_id,

    {% if var('stripe__using_subscriptions', True) %}
    subscription.subscription_id,
    subscription.billing as subscription_billing,
    subscription.start_date_at as subscription_start_date,
    subscription.ended_at as subscription_ended_at,

    {% if var('stripe__using_price', does_table_exist('price')) %}
    pricing.price_id,
    
    {% else %}
    pricing.plan_id,

    {% endif %}
    pricing.is_active as pricing_is_active,
    pricing.unit_amount as pricing_amount,
    pricing.recurring_interval as pricing_interval,
    pricing.recurring_interval_count as pricing_interval_count,
    pricing.nickname as pricing_nickname,
    pricing.product_id as pricing_product_id,
    {% endif %}

    invoice.source_relation
    
from invoice

left join charge 
    on charge.charge_id = invoice.charge_id
    and charge.source_relation = invoice.source_relation
left join invoice_line_item 
    on invoice.invoice_id = invoice_line_item.invoice_id
    and invoice.source_relation = invoice_line_item.source_relation

{% if var('stripe__using_subscriptions', True) %}
left join subscription 
    on invoice_line_item.subscription_id = subscription.subscription_id
    and invoice_line_item.source_relation = subscription.source_relation
left join pricing 
    {% if var('stripe__price', does_table_exist('price')) %}
    on invoice_line_item.price_id = pricing.price_id

    {% else %}
    on invoice_line_item.plan_id = pricing.plan_id

    {% endif %}
    and invoice_line_item.source_relation = pricing.source_relation

{% endif %}

left join customer 
    on invoice.customer_id = customer.customer_id
    and invoice.source_relation = customer.source_relation
