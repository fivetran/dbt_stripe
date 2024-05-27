with balance_transaction_enhanced as (

    select *
    from {{ ref('stripe__balance_transactions')}}

)

select 
    balance_transaction_id,
    balance_transaction_created_at,
    balance_transaction_reporting_category,
    balance_transaction_currency as currency,
    balance_transaction_amount as amount,
    charge_id,
    payment_intent_id,
    refund_id,
    dispute_id,

    {% if var('stripe__using_invoices', True) %}
    invoice_id,
    invoice_number,
    {% endif %}

    {% if var('stripe__using_subscriptions', True) %}
    subscription_id,
    {% endif %}

    transfer_id,
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
    automatic_payout_id,
    automatic_payout_effective_at,

    {% if var('stripe__using_payment_method', True) %}
    payment_method_type,
    {% endif %}
    
    card_brand,
    card_funding,
    card_country,
    charge_statement_descriptor as statement_descriptor,
    customer_facing_amount,
    balance_transaction_description,
    connected_account_id,
    connected_account_country,
    connected_account_direct_charge_id,
    source_relation

from balance_transaction_enhanced