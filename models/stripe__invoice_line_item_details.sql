{{ config(enabled=var('stripe__using_invoices', True)) }}

with invoice_line_item as (

    select *
    from {{ var('invoice_line_item') }} 

), invoice_details as (

    select *
    from {{ ref('stripe__invoice_details') }}

{% if var('stripe__using_subscriptions', True) %}
), subscription as (

    select *
    from {{ var('subscription') }}  

), price_plan as (

    select *
    from {{ var('price_plan') }}  

{% endif %}
)

select 
    invoice_line_item.invoice_line_item_id,
    invoice_line_item.invoice_id,
    invoice_line_item.invoice_item_id,
    coalesce(invoice_line_item.amount,0) as invoice_line_item_amount,
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
    invoice_line_item.unique_invoice_line_item_id,
    invoice_line_item.period_start,
    invoice_line_item.period_end,
    invoice_details.invoice_created_at,
    invoice_details.status as invoice_status,
    invoice_details.due_date as invoice_due_date,
    coalesce(invoice_details.amount_due,0) as invoice_amount_due,
    coalesce(invoice_details.amount_paid,0) as invoice_amount_paid,
    coalesce(invoice_details.subtotal,0) as invoice_subtotal,
    coalesce(invoice_details.tax,0) as invoice_tax,
    coalesce(invoice_details.total,0) as invoice_total,
    invoice_details.connected_account_id as connected_account_id,
    invoice_details.customer_id as customer_id,

    {% if var('stripe__using_subscriptions', True) %}

    subscription.billing as subscription_billing,
    subscription.start_date_at as subscription_start_date,
    subscription.ended_at as subscription_ended_at,
    price_plan.is_active as price_plan_is_active,
    price_plan.unit_amount as price_plan_amount,
    price_plan.recurring_interval as price_plan_interval,
    price_plan.recurring_interval_count as price_plan_interval_count,
    price_plan.nickname as price_plan_nickname,
    price_plan.product_id as price_plan_product_id,
    {% endif %}

    invoice_line_item.source_relation
    
from invoice_line_item

left join invoice_details 
    on invoice_line_item.invoice_id = invoice_details.invoice_id
    and invoice_line_item.source_relation = invoice_details.source_relation

{% if var('stripe__using_subscriptions', True) %}

left join subscription
    on invoice_line_item.subscription_id = subscription.subscription_id
    and invoice_line_item.source_relation = subscription.source_relation

left join price_plan

{% if var('stripe__using_price', stripe_source.does_table_exist('price')==exists) %}
    on invoice_line_item.price_id = price_plan.price_plan_id
{% else %}
    on invoice_line_item.plan_id = price_plan.price_plan_id
{% endif %}

    and invoice_line_item.source_relation = price_plan.source_relation

{% endif %}