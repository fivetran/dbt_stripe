{{ config(enabled=var('stripe__using_invoices', True)) }}

with invoice_line_item as (

    select *
    from {{ var('invoice_line_item') }} 

), invoice_details as (

    select *
    from {{ ref('stripe__invoice_details') }}

), subscription as (

    select *
    from {{ var('subscription') }}  

{% if var('stripe__using_subscriptions', True) %}
), pricing as (

    select *
    from {{ var('pricing') }}  

{% endif %}
)

select 
    invoice_line_item.invoice_line_item_id,
    invoice_line_item.invoice_id,
    invoice_line_item.invoice_item_id,
    invoice_line_item.amount as invoice_line_item_amount,
    invoice_line_item.currency,
    invoice_line_item.description as invoice_line_item_memo,
    invoice_line_item.is_discountable,
    invoice_line_item.plan_id,
    invoice_line_item.price_id,
    invoice_line_item.proration,
    invoice_line_item.quantity,
    invoice_line_item.subscription_id,
    invoice_line_item.subscription_item_id,
    invoice_line_item.type,
    invoice_line_item.unique_id,
    invoice_line_item.period_start,
    invoice_line_item.period_end,
    invoice_details.invoice_created_at,
    invoice_details.status as invoice_status,
    invoice_details.due_date as invoice_due_date,
    invoice_details.amount_due as invoice_amount_due,
    invoice_details.amount_paid as invoice_amount_paid,
    invoice_details.subtotal as invoice_subtotal,
    invoice_details.tax as invoice_tax,
    invoice_details.total as invoice_total,
    invoice_details.connected_account_id as connected_account_id,
    invoice_details.customer_id as customer_id

    {% if var('stripe__using_subscriptions', True) %}
    ,
    subscription.billing as subscription_billing,
    subscription.start_date_at as subscription_start_date,
    subscription.ended_at as subscription_ended_at,
    pricing.is_active as pricing_is_active,
    pricing.unit_amount as pricing_amount,
    pricing.recurring_interval as pricing_interval,
    pricing.recurring_interval_count as pricing_interval_count,
    pricing.nickname as pricing_nickname,
    pricing.product_id as pricing_product_id
    {% endif %}
    
from invoice_line_item

left join invoice_details 
    on invoice_line_item.invoice_id = invoice_details.invoice_id
    and invoice_line_item.source_relation = invoice_details.source_relation

{% if var('stripe__using_subscriptions', True) %}

left join subscription
    on invoice_line_item.subscription_id = subscription.subscription_id
    and invoice_line_item.source_relation = subscription.source_relation

left join pricing 
    {% if var('stripe__using_price', does_table_exist('price')) %}
    on invoice_line_item.price_id = pricing.price_id

    {% else %}
    on invoice_line_item.plan_id = pricing.plan_id

    {% endif %}
    and invoice_line_item.source_relation = pricing.source_relation

{% endif %}