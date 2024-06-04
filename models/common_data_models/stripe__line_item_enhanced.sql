{{ config(enabled=var('stripe__using_invoices', True)) }}

with invoice_line_item as (

    select *
    from {{ var('invoice_line_item') }} 

), invoice as (

    select *
    from {{ var('invoice') }}

{% if var('stripe__using_subscriptions', True) %}
), subscription as (

    select *
    from {{ var('subscription') }}  

), price_plan as (

    select *
    from {{ var('price_plan') }}  

{% endif %}

), payment_intent as (

    select *
    from {{ var('payment_intent') }} 

), payment_method as (

    select * 
    from {{ var('payment_method')}}

), fee as (

    select *
    from {{ var('fee') }} 

), balance_transaction as (

    select *
    from {{ var('balance_transaction') }} 

), charge as (

    select *
    from {{ var('charge') }} 

), refund as (

    select *
    from {{ var('refund') }} 

), customer as (

    select *
    from {{ var('customer') }} 

), invoice_line_item_enhanced as (

    select
    invoice_line_item.invoice_id as header_id,
    invoice_line_item.invoice_line_item_id as line_item_id,
    ow_number() over (partition by invoice_line_item.invoice_id) as line_item_index,
    record_type, -- check
    invoice.created_at as created_at,
    invoice_line_item.currency as currency,
    invoice.status as line_item_status,
    invoice.status as header_status,
    price_plan.product_id as product_id,
    price_plan.nickname as product_name,
    null as product_type,
    null as product_category,
    invoice_line_item.quantity as quantity,
    (invoice_line_item.amount/invoice_line_item.quantity) as unit_amount,
    null as discount_amount,
    null as tax_rate,
    null as tax_amount,
    invoice_line_item.amount as total_amount,
    payment_intent.payment_intent_id as payment_id,
    payment_method.type as payment_method,
    charge.created_at as payment_at,
    null as as fee_amount,
    refund_id,
    null as refund_amount,
    null as refunded_at,
    subscription_id,
    subscription_period_started_at,
    subscription_period_ended_at,
    subscription_status,
    customer_id,
    customer_level,
    customer_name,
    customer_company,
    customer_email,
    customer_city,
    customer_country

    from invoice_line_item

    left join invoice_details 
        on invoice_line_item.invoice_id = invoice_details.invoice_id
        and invoice_line_item.source_relation = invoice_details.source_relation

    left join invoice
        on invoice.invoice_id = invoice_line_item.invoice_id
        and invoice.source_relation = invoice_line_item.source_relation

    left join charge 
        on invoice.charge_id = charge.charge_id
        and invoice.invoice_id = charge.invoice_id
        and invoice.source_relation = charge.source_relation

    left join balance_transaction
        on charge.balance_transaction_id = balance_transaction.balance_transaction_id

    left join refund 
        on balance_transaction.balance_transaction_id = refund.balance_transaction_id

    left join account connected_account
        on balance_transaction.connected_account_id = connected_account.account_id

    left join payment_intent
        on charge.payment_intent_id = payment_intent.payment_intent_id

    left join payment_method 
        on charge.payment_method_id = payment_method.payment_method_id

    left join customer 
        on invoice.customer_id = customer.customer_id
        and invoice.source_relation = customer.source_relation

    {% if var('stripe__using_subscriptions', True) %}

    left join subscription
        on invoice_line_item.subscription_id = subscription.subscription_id
        and invoice_line_item.source_relation = subscription.source_relation

    left join price_plan

    {% if var('stripe__using_price', stripe_source.does_table_exist('price')) %}
        on invoice_line_item.price_id = price_plan.price_plan_id
    {% else %}
        on invoice_line_item.plan_id = price_plan.price_plan_id
    {% endif %}

        and invoice_line_item.source_relation = price_plan.source_relation

    {% endif %}

), invoice_enhanced as 

    header_id,
    line_item_id,
    line_item_index,
    record_type,
    created_at,
    currency,
    line_item_status,
    header_status,
    product_id,
    product_name,
    product_type,
    product_category,
    quantity,
    unit_amount,
    discount_amount,
    tax_rate,
    invoice.tax as tax_amount,
    total_amount,
    payment_id,
    payment_method,
    charge.created_at as payment_at,
    balance_transaction.fee as fee_amount ,
    refund.refund_id,
    refund.amount as refund_amount,
    balance_transaction.created_at as refunded_at, -- check

    {% if var('stripe__using_subscriptions', True) %}

    subscription.subscription_id,
    subscription.current_period_start as subscription_period_started_at,
    subscription.current_period_end as subscription_period_ended_at,
    subscription.status as subscription_status,
    customer.customer_id as customer_id,
    null as customer_level,
    account.company_name as customer_name, -- check- should we be using account?
    account.company_name as customer_company,  -- check- should we be using account?
    customer.email as customer_email,
    customer.customer_address_city as customer_city,
    customer.customer_address_country as customer_country

    from invoice_line_item

    left join invoice_details 
        on invoice_line_item.invoice_id = invoice_details.invoice_id
        and invoice_line_item.source_relation = invoice_details.source_relation

    left join invoice
        on invoice.invoice_id = invoice_line_item.invoice_id
        and invoice.source_relation = invoice_line_item.source_relation

    left join charge 
        on invoice.charge_id = charge.charge_id
        and invoice.invoice_id = charge.invoice_id
        and invoice.source_relation = charge.source_relation

    left join balance_transaction
        on charge.balance_transaction_id = balance_transaction.balance_transaction_id

    left join refund 
        on balance_transaction.balance_transaction_id = refund.balance_transaction_id

    left join account connected_account
        on balance_transaction.connected_account_id = connected_account.account_id

    left join payment_intent
        on charge.payment_intent_id = payment_intent.payment_intent_id

    left join payment_method 
        on charge.payment_method_id = payment_method.payment_method_id

    left join customer 
        on invoice.customer_id = customer.customer_id
        and invoice.source_relation = customer.source_relation

    {% if var('stripe__using_subscriptions', True) %}

    left join subscription
        on invoice_line_item.subscription_id = subscription.subscription_id
        and invoice_line_item.source_relation = subscription.source_relation

    left join price_plan

    {% if var('stripe__using_price', stripe_source.does_table_exist('price')) %}
        on invoice_line_item.price_id = price_plan.price_plan_id
    {% else %}
        on invoice_line_item.plan_id = price_plan.price_plan_id
    {% endif %}

        and invoice_line_item.source_relation = price_plan.source_relation

    {% endif %}