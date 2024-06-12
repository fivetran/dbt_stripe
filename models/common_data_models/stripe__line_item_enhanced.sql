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

), product as (

    select *
    from {{ var('product') }}

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

), account as (

    select *
    from {{ var('account') }}

), balance_transaction as (

    select *
    from {{ var('balance_transaction') }} 

), charge as (

    select *
    from {{ var('charge') }} 

), discount as (

    select *
    from {{ var('discount') }}

), refund as (

    select *
    from {{ var('refund') }} 

), customer as (

    select *
    from {{ var('customer') }} 

), enhanced as (

    select
        invoice_line_item.invoice_id as header_id,
        cast(invoice_line_item.invoice_line_item_id as {{ dbt.type_string() }}) as line_item_id,
        row_number() over (partition by invoice_line_item.invoice_id order by invoice_line_item.amount desc) as line_item_index,
        invoice.created_at as created_at,
        cast(invoice_line_item.currency as {{ dbt.type_string() }}) as currency,
        cast(invoice.status as {{ dbt.type_string() }}) as header_status,
        cast(price_plan.product_id as {{ dbt.type_string() }}) as product_id, -- The ID of the product this price is associated with. https://docs.stripe.com/api/invoices/line_item#invoice_line_item_object-price-product
        cast(product.name as {{ dbt.type_string() }}) as product_name,
        cast(balance_transaction.type as {{ dbt.type_string() }}) as transaction_type,
        cast(invoice_line_item.type as {{ dbt.type_string() }}) as billing_type,
        cast(product.type as {{ dbt.type_string() }}) as product_type,
        cast(invoice_line_item.quantity as {{ dbt.type_int() }}) as quantity,
        cast((invoice_line_item.amount/invoice_line_item.quantity) as {{ dbt.type_int() }}) as unit_amount,
        cast(discount.amount as {{ dbt.type_int() }}) as discount_amount,
        cast(invoice.tax as {{ dbt.type_int() }}) as tax_amount,
        cast(invoice.total as {{ dbt.type_int() }}) as total_amount,
        cast(payment_intent.payment_intent_id as {{ dbt.type_string() }}) as payment_id,
        cast(payment_method.payment_method_id as {{ dbt.type_string() }}) as payment_method_id,
        cast(payment_method.type as {{ dbt.type_string() }}) as payment_method_name,
        cast(charge.created_at as {{ dbt.type_timestamp() }}) as payment_at,
        cast(balance_transaction.fee as {{ dbt.type_int() }}) as fee_amount,
        cast(refund.amount as {{ dbt.type_int() }}) as refund_amount,
        cast(invoice.subscription_id as {{ dbt.type_string() }}) as subscription_id,

        {% if var('stripe__using_subscriptions', True) %}

        cast(subscription.current_period_start as {{ dbt.type_timestamp() }}) as subscription_period_started_at,
        cast(subscription.current_period_end as {{ dbt.type_timestamp() }}) as subscription_period_ended_at,
        cast(subscription.status as {{ dbt.type_string() }}) as subscription_status,

        {% endif %}

        cast(invoice.customer_id as {{ dbt.type_string() }}) as customer_id,
        cast(null as {{ dbt.type_string() }}) as customer_level,
        cast(customer.customer_name as {{ dbt.type_string() }}) as customer_name, 
        cast(connected_account.company_name as {{ dbt.type_string() }}) as customer_company, 
        cast(customer.email as {{ dbt.type_string() }}) as customer_email,
        cast(customer.customer_address_city as {{ dbt.type_string() }}) as customer_city,
        cast(customer.customer_address_country as {{ dbt.type_string() }}) as customer_country

    from invoice_line_item

    left join invoice
        on invoice.invoice_id = invoice_line_item.invoice_id

    left join charge 
        on invoice.charge_id = charge.charge_id
        and invoice.invoice_id = charge.invoice_id

    left join balance_transaction
        on charge.balance_transaction_id = balance_transaction.balance_transaction_id

    left join discount 
        on invoice.invoice_id = discount.invoice_id

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

    {% if var('stripe__using_subscriptions', True) %}

    left join subscription
        on invoice.subscription_id = subscription.subscription_id

    left join price_plan

    {% if var('stripe__using_price', stripe_source.does_table_exist('price')) %}
        on invoice_line_item.price_id = price_plan.price_plan_id
    {% else %}
        on invoice_line_item.plan_id = price_plan.price_plan_id
    {% endif %}

    left join product
        on price_plan.product_id = product.product_id
    {% endif %}

), final as (

-- invoice_line_item_level
    select
        header_id,
        line_item_id,
        line_item_index,
        'line_item' as record_type,
        created_at,
        currency,
        header_status,
        product_id,
        product_name,
        cast(null as {{ dbt.type_string() }}) as transaction_type,
        billing_type,
        product_type,
        quantity,
        unit_amount,
        cast(null as {{ dbt.type_int() }}) as discount_amount,
        cast(null as {{ dbt.type_int() }}) as tax_amount,
        total_amount,
        payment_id,
        payment_method_id,
        payment_method_name,
        payment_at,
        cast(null as {{ dbt.type_int() }}) as fee_amount,
        cast(null as {{ dbt.type_int() }}) as refund_amount,
        subscription_id,
        subscription_period_started_at,
        subscription_period_ended_at,
        subscription_status,
        customer_id,
        cast(null as {{ dbt.type_string() }}) as customer_level,
        customer_name,
        customer_company,
        customer_email,
        customer_city,
        customer_country
    from enhanced

    union all

    -- create records for fields only pertinent at the invoice level
    select
        header_id,
        cast(null as {{ dbt.type_string() }}) as line_item_id,
        line_item_index,
        'header' as record_type,
        created_at,
        currency,
        header_status,
        cast(null as {{ dbt.type_string() }}) as product_id,
        cast(null as {{ dbt.type_string() }}) as product_name,
        transaction_type,
        cast(null as {{ dbt.type_string() }}) as billing_type,
        cast(null as {{ dbt.type_string() }}) as product_type,
        cast(null as {{ dbt.type_float() }}) as quantity,
        cast(null as {{ dbt.type_float() }}) as unit_amount,
        discount_amount,
        tax_amount,
        cast(null as {{ dbt.type_float() }}) as total_amount,
        payment_id,
        payment_method_id,
        payment_method_name,
        payment_at,
        fee_amount,
        refund_amount,
        subscription_id,
        subscription_period_started_at,
        subscription_period_ended_at,
        subscription_status,
        customer_id,
        cast(null as {{ dbt.type_string() }}) as customer_level,
        customer_name,
        customer_company,
        customer_email,
        customer_city,
        customer_country
    from enhanced
    where line_item_index = 1
        and discount_amount is not null or tax_amount is not null or fee_amount is not null or refund_amount is not null
)

select *
from final


