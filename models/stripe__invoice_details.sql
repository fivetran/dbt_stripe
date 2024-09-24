{{ config(enabled=var('stripe__using_invoices', True)) }}

with invoice as (

    select *
    from {{ var('invoice') }}  

), charge as (

    select *
    from {{ var('charge') }}  

), invoice_line_item as (

    select
        invoice_id,
        source_relation,
        coalesce(count(distinct unique_invoice_line_item_id),0) as number_of_line_items,
        coalesce(sum(quantity),0) as total_quantity

    from {{ var('invoice_line_item') }}  
    group by 1,2

), customer as (

    select *
    from {{ var('customer') }}  

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
    invoice.invoice_id,
    invoice.number as invoice_number,
    invoice.created_at as invoice_created_at,
    invoice.period_start,
    invoice.period_end,
    invoice.status,
    invoice.due_date,
    invoice.currency,
    coalesce(invoice.amount_due,0) as amount_due,
    coalesce(invoice.amount_paid,0) as amount_paid,
    coalesce(invoice.subtotal,0) as subtotal,
    coalesce(invoice.tax,0) as tax,
    coalesce(invoice.total,0) as total,
    coalesce(invoice.amount_remaining,0) as amount_remaining,
    coalesce(invoice.attempt_count,0) as attempt_count,
    invoice.description as invoice_memo,
    invoice_line_item.number_of_line_items,
    invoice_line_item.total_quantity,
    charge.balance_transaction_id,
    charge.amount as charge_amount, 
    charge.status as charge_status,
    charge.connected_account_id, 
    charge.created_at as charge_created_at,
    charge.is_refunded as charge_is_refunded,
    customer.customer_id,
    customer.description as customer_description,
    customer.account_balance as customer_account_balance,
    customer.currency as customer_currency,
    customer.is_delinquent as customer_is_delinquent,
    customer.email as customer_email,
    
    {% if var('stripe__using_subscriptions', True) %}
    subscription.subscription_id,
    subscription.billing as subscription_billing,
    subscription.start_date_at as subscription_start_date,
    subscription.ended_at as subscription_ended_at,

    {% endif %}
    invoice.source_relation

from invoice

left join invoice_line_item 
    on invoice.invoice_id = invoice_line_item.invoice_id
    {{ stripe_include_source_relation_in_join('invoice', 'invoice_line_item') }}

left join charge 
    on invoice.charge_id = charge.charge_id
    and invoice.invoice_id = charge.invoice_id
    {{ stripe_include_source_relation_in_join('invoice', 'charge') }}

{% if var('stripe__using_subscriptions', True) %}
left join subscription
    on invoice.subscription_id = subscription.subscription_id
    {{ stripe_include_source_relation_in_join('invoice', 'subscription') }}

{% endif %}

left join customer 
    on invoice.customer_id = customer.customer_id
    {{ stripe_include_source_relation_in_join('invoice', 'customer') }}