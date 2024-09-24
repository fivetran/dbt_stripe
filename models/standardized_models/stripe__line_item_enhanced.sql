{{ config(
    enabled=(
        var('stripe__standardized_billing_model_enabled', False) and (var('stripe__using_invoices', True))
    )
) }}


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

    select
        invoice_id,
        source_relation,
        sum(amount) as total_discount_amount
    from {{ var('discount') }}
    group by 1, 2

), line_item_aggregate as (

    select
        invoice_id,
        source_relation,
        sum(amount) as total_line_item_amount
    from {{ var('invoice_line_item') }}
    group by 1, 2

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

        cast({{ "price_plan.product_id" if var('stripe__using_subscriptions', True) else 'null' }} as {{ dbt.type_string() }}) as product_id, -- The ID of the product this price is associated with. https://docs.stripe.com/api/invoices/line_item#invoice_line_item_object-price-product
        cast({{ "product.name" if var('stripe__using_subscriptions', True) else 'null' }} as {{ dbt.type_string() }}) as product_name,
        cast({{ "product.type" if var('stripe__using_subscriptions', True) else 'null' }} as {{ dbt.type_string() }}) as product_type,

        cast(balance_transaction.type as {{ dbt.type_string() }}) as transaction_type,
        cast(invoice_line_item.type as {{ dbt.type_string() }}) as billing_type,
        cast(invoice_line_item.quantity as {{ dbt.type_numeric() }}) as quantity,
        cast((invoice_line_item.amount/invoice_line_item.quantity) as {{ dbt.type_numeric() }}) as unit_amount,
        cast(discount.total_discount_amount as {{ dbt.type_numeric() }}) as discount_amount,
        cast(invoice.tax as {{ dbt.type_numeric() }}) as tax_amount,
        cast(line_item_aggregate.total_line_item_amount as {{ dbt.type_numeric() }}) as total_line_item_amount,
        cast(invoice.total as {{ dbt.type_numeric() }}) as total_invoice_amount,
        cast(invoice_line_item.amount as {{ dbt.type_numeric() }}) as total_amount,
        cast(payment_intent.payment_intent_id as {{ dbt.type_string() }}) as payment_id,
        cast(payment_method.payment_method_id as {{ dbt.type_string() }}) as payment_method_id,
        cast(payment_method.type as {{ dbt.type_string() }}) as payment_method,
        cast(charge.created_at as {{ dbt.type_timestamp() }}) as payment_at,
        cast(balance_transaction.fee as {{ dbt.type_numeric() }}) as fee_amount,
        cast(refund.amount as {{ dbt.type_numeric() }}) as refund_amount,
        cast(invoice.subscription_id as {{ dbt.type_string() }}) as subscription_id,

        cast({{ "product.name" if var('stripe__using_subscriptions', True) else 'null' }} as {{ dbt.type_string() }}) as subscription_plan,
        cast({{ "subscription.current_period_start" if var('stripe__using_subscriptions', True) else 'null' }} as {{ dbt.type_timestamp() }}) as subscription_period_started_at,
        cast({{ "subscription.current_period_end" if var('stripe__using_subscriptions', True) else 'null' }} as {{ dbt.type_timestamp() }}) as subscription_period_ended_at,
        cast({{ "subscription.status" if var('stripe__using_subscriptions', True) else 'null' }} as {{ dbt.type_string() }}) as subscription_status,

        cast(invoice.customer_id as {{ dbt.type_string() }}) as customer_id,
        cast(customer.created_at as {{ dbt.type_timestamp() }}) as customer_created_at,
        'customer' as customer_level,
        cast(customer.customer_name as {{ dbt.type_string() }}) as customer_name, 
        cast(connected_account.company_name as {{ dbt.type_string() }}) as customer_company, 
        cast(customer.email as {{ dbt.type_string() }}) as customer_email,
        cast(customer.customer_address_city as {{ dbt.type_string() }}) as customer_city,
        cast(customer.customer_address_country as {{ dbt.type_string() }}) as customer_country,
        invoice_line_item.source_relation

    from invoice_line_item

    left join invoice
        on invoice.invoice_id = invoice_line_item.invoice_id
        {{ stripe_include_source_relation_in_join('invoice', 'invoice_line_item') }}

    left join line_item_aggregate
        on invoice.invoice_id = line_item_aggregate.invoice_id
        {{ stripe_include_source_relation_in_join('invoice', 'line_item_aggregate') }}

    left join charge 
        on invoice.charge_id = charge.charge_id
        and invoice.invoice_id = charge.invoice_id
        {{ stripe_include_source_relation_in_join('invoice', 'charge') }}

    left join balance_transaction
        on charge.balance_transaction_id = balance_transaction.balance_transaction_id
        {{ stripe_include_source_relation_in_join('invoice', 'balance_transaction') }}

    left join discount 
        on invoice.invoice_id = discount.invoice_id
        {{ stripe_include_source_relation_in_join('invoice', 'discount') }}

    left join refund 
        on balance_transaction.balance_transaction_id = refund.balance_transaction_id
        {{ stripe_include_source_relation_in_join('invoice', 'refund') }}

    left join account connected_account
        on balance_transaction.connected_account_id = connected_account.account_id
        {{ stripe_include_source_relation_in_join('invoice', 'connected_account') }}

    left join payment_intent
        on charge.payment_intent_id = payment_intent.payment_intent_id
        {{ stripe_include_source_relation_in_join('invoice', 'payment_intent') }}

    left join payment_method 
        on charge.payment_method_id = payment_method.payment_method_id
        {{ stripe_include_source_relation_in_join('invoice', 'payment_method') }}

    left join customer 
        on invoice.customer_id = customer.customer_id
        {{ stripe_include_source_relation_in_join('invoice', 'customer') }}

    {% if var('stripe__using_subscriptions', True) %}

    left join subscription
        on invoice.subscription_id = subscription.subscription_id
        {{ stripe_include_source_relation_in_join('invoice', 'subscription') }}

    left join price_plan

    {% if var('stripe__using_price', stripe_source.does_table_exist('price')) %}
        on invoice_line_item.price_id = price_plan.price_plan_id
    {% else %}
        on invoice_line_item.plan_id = price_plan.price_plan_id
    {% endif %}
        {{ stripe_include_source_relation_in_join('invoice_line_item', 'price_plan') }}

    left join product
        on price_plan.product_id = product.product_id
        {{ stripe_include_source_relation_in_join('price_plan', 'product') }}
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
        transaction_type,
        billing_type,
        product_type,
        quantity,
        unit_amount,
        cast(null as {{ dbt.type_numeric() }}) as discount_amount,
        cast(null as {{ dbt.type_numeric() }}) as tax_amount,
        total_amount,
        payment_id,
        payment_method_id,
        payment_method,
        payment_at,
        cast(null as {{ dbt.type_numeric() }}) as fee_amount,
        cast(null as {{ dbt.type_numeric() }}) as refund_amount,
        subscription_id,
        subscription_plan,
        subscription_period_started_at,
        subscription_period_ended_at,
        subscription_status,
        customer_id,
        customer_created_at,
        customer_level,
        customer_name,
        customer_company,
        customer_email,
        customer_city,
        customer_country,
        source_relation
    from enhanced

    union all

    -- create records for fields only pertinent at the invoice level
    select
        header_id,
        cast(null as {{ dbt.type_string() }}) as line_item_id,
        cast(0 as {{ dbt.type_int() }}) as line_item_index,
        'header' as record_type,
        created_at,
        currency,
        header_status,
        cast(null as {{ dbt.type_string() }}) as product_id,
        cast(null as {{ dbt.type_string() }}) as product_name,
        transaction_type,
        billing_type,
        cast(null as {{ dbt.type_string() }}) as product_type,
        cast(null as {{ dbt.type_float() }}) as quantity,
        cast(null as {{ dbt.type_float() }}) as unit_amount,
        discount_amount,
        tax_amount,
        cast((total_invoice_amount - total_line_item_amount) as {{ dbt.type_float() }}) as total_amount,
        payment_id,
        payment_method_id,
        payment_method,
        payment_at,
        fee_amount,
        refund_amount,
        subscription_id,
        subscription_plan,
        subscription_period_started_at,
        subscription_period_ended_at,
        subscription_status,
        customer_id,
        customer_created_at,
        customer_level,
        customer_name,
        customer_company,
        customer_email,
        customer_city,
        customer_country,
        source_relation
    from enhanced
    where line_item_index = 1
        and (discount_amount is not null or tax_amount is not null or fee_amount is not null or refund_amount is not null)
)

select *
from final