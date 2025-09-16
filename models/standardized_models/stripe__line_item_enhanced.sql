{{ config(
    enabled=(
        var('stripe__standardized_billing_model_enabled', True) and (var('stripe__using_invoices', True))
    )
) }}


with invoice_line_item as (

    select *
    from {{ ref('stg_stripe__invoice_line_item') }} 

), invoice as (

    select *
    from {{ ref('stg_stripe__invoice') }}

{% if var('stripe__using_subscriptions', True) %}
), subscription as (

    select *
    from {{ ref('stg_stripe__subscription') }}  

), subscription_item as (

    select *
    from {{ ref('int_stripe__deduped_subscription_item') }}  

--Newer Stripe connections will store current_period_start/end fields in SUBSCRIPTION_ITEM while older ones house these fields in SUBSCRIPTION_HISTORY -> grab both and coalesce
), subscription_item_merge as (
    select 
           coalesce(subscription.subscription_id, subscription_item.subscription_id) as subscription_id,
           subscription.status,
           coalesce(subscription.source_relation, subscription_item.source_relation) as source_relation,
           coalesce(subscription.current_period_start, subscription_item.current_period_start) as current_period_start,
           coalesce(subscription.current_period_end, subscription_item.current_period_end) as current_period_end
    from subscription
    left join  subscription_item
        on subscription.subscription_id = subscription_item.subscription_id
        and subscription.source_relation = subscription_item.source_relation

), price_plan as (

    select *
    from {{ ref('stg_stripe__price_plan') }}  

), product as (

    select *
    from {{ ref('stg_stripe__product') }}

{% endif %}

), payment_intent as (

    select *
    from {{ ref('stg_stripe__payment_intent') }} 

{% if var('stripe__using_payment_method', True) %}
), payment_method as (

    select *
    from {{ ref('stg_stripe__payment_method') }}

{% endif %}

), fee as (

    select *
    from {{ ref('stg_stripe__fee') }} 

), account as (

    select *
    from {{ ref('stg_stripe__account') }}

), balance_transaction as (

    select *
    from {{ ref('stg_stripe__balance_transaction') }} 

), charge as (

    select *
    from {{ ref('stg_stripe__charge') }} 

), discount as (

    select
        invoice_id,
        source_relation,
        sum(amount) as total_discount_amount
    from {{ ref('stg_stripe__discount') }}
    group by 1, 2

), line_item_aggregate as (

    select
        invoice_id,
        source_relation,
        sum(amount) as total_line_item_amount
    from {{ ref('stg_stripe__invoice_line_item') }}
    group by 1, 2

), refund as (

    select *
    from {{ ref('stg_stripe__refund') }} 

), customer as (

    select *
    from {{ ref('stg_stripe__customer') }} 

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

        case 
            when bt_refund.balance_transaction_id is not null and bt_charge.balance_transaction_id is not null then 'charge + refund'
            when bt_charge.balance_transaction_id is not null then 'charge'
            when bt_refund.balance_transaction_id is not null then 'payment intent + refund'
            else coalesce(bt_charge.type, bt_refund.type)
        end as transaction_type,
            
        cast(invoice_line_item.type as {{ dbt.type_string() }}) as billing_type,
        cast(invoice_line_item.quantity as {{ dbt.type_numeric() }}) as quantity,

        cast(case 
                when invoice_line_item.quantity = 0 then 0
                else (invoice_line_item.amount / invoice_line_item.quantity) 
            end as {{ dbt.type_numeric() }}) as unit_amount,

        cast(discount.total_discount_amount as {{ dbt.type_numeric() }}) as discount_amount,
        cast(invoice.tax as {{ dbt.type_numeric() }}) as tax_amount,
        cast(line_item_aggregate.total_line_item_amount as {{ dbt.type_numeric() }}) as total_line_item_amount,
        cast(invoice.total as {{ dbt.type_numeric() }}) as total_invoice_amount,
        cast(invoice_line_item.amount as {{ dbt.type_numeric() }}) as total_amount,
        cast(payment_intent.payment_intent_id as {{ dbt.type_string() }}) as payment_id,
        cast({{ "payment_method.payment_method_id" if var('stripe__using_payment_method', True) else 'null' }} as {{ dbt.type_string() }}) as payment_method_id,
        cast({{ "payment_method.type" if var('stripe__using_payment_method', True) else 'null' }} as {{ dbt.type_string() }}) as payment_method,
        cast(charge.created_at as {{ dbt.type_timestamp() }}) as payment_at,
        cast(coalesce(bt_charge.fee, 0) as {{ dbt.type_numeric() }}) + cast(coalesce(bt_refund.fee, 0) as {{ dbt.type_numeric() }}) as fee_amount,
        cast(refund.amount as {{ dbt.type_numeric() }}) as refund_amount,
        cast(invoice.subscription_id as {{ dbt.type_string() }}) as subscription_id,

        cast({{ "product.name" if var('stripe__using_subscriptions', True) else 'null' }} as {{ dbt.type_string() }}) as subscription_plan,
        cast({{ "subscription_item_merge.current_period_start" if var('stripe__using_subscriptions', True) else 'null' }} as {{ dbt.type_timestamp() }}) as subscription_period_started_at,
        cast({{ "subscription_item_merge.current_period_end" if var('stripe__using_subscriptions', True) else 'null' }} as {{ dbt.type_timestamp() }}) as subscription_period_ended_at,
        cast({{ "subscription_item_merge.status" if var('stripe__using_subscriptions', True) else 'null' }} as {{ dbt.type_string() }}) as subscription_status,

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
        and invoice.source_relation = invoice_line_item.source_relation

    left join line_item_aggregate
        on invoice.invoice_id = line_item_aggregate.invoice_id
        and invoice.source_relation = line_item_aggregate.source_relation

    left join charge 
        on invoice.charge_id = charge.charge_id
        and invoice.invoice_id = charge.invoice_id
        and invoice.source_relation = charge.source_relation

    left join refund
        on charge.charge_id = refund.charge_id
        and charge.source_relation = refund.source_relation

    left join balance_transaction bt_charge
        on charge.balance_transaction_id = bt_charge.balance_transaction_id
        and charge.source_relation = bt_charge.source_relation

    left join balance_transaction bt_refund
        on refund.balance_transaction_id = bt_refund.balance_transaction_id
        and refund.source_relation = bt_refund.source_relation

    left join discount 
        on invoice.invoice_id = discount.invoice_id
        and invoice.source_relation = discount.source_relation

    left join account connected_account
        on coalesce(bt_charge.connected_account_id, bt_refund.connected_account_id)  = connected_account.account_id
        and coalesce(bt_charge.source_relation, bt_refund.source_relation) = connected_account.source_relation

    left join payment_intent
        on charge.payment_intent_id = payment_intent.payment_intent_id
        and charge.source_relation = payment_intent.source_relation

    {% if var('stripe__using_payment_method', True) %}
    left join payment_method
        on charge.payment_method_id = payment_method.payment_method_id
        and charge.source_relation = payment_method.source_relation
    {% endif %}

    left join customer 
        on invoice.customer_id = customer.customer_id
        and invoice.source_relation = customer.source_relation

    {% if var('stripe__using_subscriptions', True) %}

    left join subscription_item_merge
        on invoice.subscription_id = subscription_item_merge.subscription_id
        and invoice.source_relation = subscription_item_merge.source_relation

    left join price_plan

    {% if var('stripe__using_price', stripe.does_table_exist('price')=='exists') %}
        on invoice_line_item.price_id = price_plan.price_plan_id
    {% else %}
        on invoice_line_item.plan_id = price_plan.price_plan_id
    {% endif %}
        and invoice_line_item.source_relation = price_plan.source_relation

    left join product
        on price_plan.product_id = product.product_id
        and price_plan.source_relation = product.source_relation
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
        and (discount_amount is not null or tax_amount is not null or fee_amount != 0 or refund_amount is not null)
)

select *
from final