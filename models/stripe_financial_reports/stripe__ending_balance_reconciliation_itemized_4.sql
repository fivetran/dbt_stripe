with balance_transaction_enhanced as (

    select *
    from {{ ref('stripe__balance_transactions')}}
    where automatic_payout_id is not null

)

select
    automatic_payout_id,
    payout_arrival_date_at as automatic_payout_effective_at,
    balance_transaction_id,
    balance_transaction_created_at as created,
    balance_transaction_available_on as available_on,
    balance_transaction_currency as currency,
    balance_transaction_amount as gross,
    balance_transaction_fee as fee,
    balance_transaction_net as net,
    balance_transaction_reporting_category as reporting_category,
    balance_transaction_source_id as source_id,
    balance_transaction_description as description,
    customer_facing_amount,
    customer_facing_currency,
    customer_id,
    customer_email,
    customer_name,
    customer_description,
    customer_shipping_address_line_1,
    customer_shipping_address_line_2,
    customer_shipping_address_city,
    customer_shipping_address_state,
    customer_shipping_address_postal_code,
    customer_shipping_address_country,
    customer_address_line_1,
    customer_address_line_2,
    customer_address_city,
    customer_address_state,
    customer_address_postal_code,
    customer_address_country,
    charge_shipping_address_line_1 as shipping_address_line_1,
    charge_shipping_address_line_2 as shipping_address_line_2,
    charge_shipping_address_city as shipping_address_city,
    charge_shipping_address_state as shipping_address_state,
    charge_shipping_address_postal_code as shipping_address_postal_code,
    charge_shipping_address_country as shipping_address_country,
    card_address_line_1,
    card_address_line_2,
    card_address_city,
    card_address_state,
    card_address_postal_code,
    card_address_country,
    charge_id,
    payment_intent_id,
    charge_created_at as charge_created,

    {% if var('stripe__using_invoices', True) %}
    invoice_id,
    invoice_number,
    {% endif %}

    {% if var('stripe__using_subscriptions', True) %}
    subscription_id,
    {% endif %}
    
    {% if var('stripe__using_payment_method', True) %}
    payment_method_type,
    {% endif %}
    
    card_brand,
    card_funding,
    card_country,
    charge_statement_descriptor as statement_descriptor,
    dispute_reasons,
    connected_account_id, 
    connected_account_country,
    connected_account_direct_charge_id,
    source_relation

from balance_transaction_enhanced
