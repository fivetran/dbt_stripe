
with balance_transaction_enhanced as (

    select *
    from {{ ref('stripe__balance_transactions')}}

)

select 
    balance_transaction_id,
    balance_transaction_created_at as created,
    balance_transaction_available_on as available_on,
    balance_transaction_currency as currency,
    balance_transaction_amount as gross,
    balance_transaction_fee as fee,
    balance_transaction_net as net,
    reporting_category,
    source_id,
    balance_transaction_description as description,
    customer_facing_amount,
    customer_facing_currency,
    automatic_payout_id,
    automatic_payout_effective_at,
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
    shipping_address_line_1,
    shipping_address_line_2,
    shipping_address_city,
    shipping_address_state,
    shipping_address_postal_code,
    shipping_address_country,
    card_address_line_1,
    card_address_line_2,
    card_address_city,
    card_address_state,
    card_address_postal_code,
    card_address_country,
    charge_id,
    payment_intent_id,
    charge_created_at,

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
    statement_descriptor,
    dispute_reason,
    connected_account_id,
    connected_account_country,
    connected_account_name,
    connected_account_direct_charge_id,
    payment_metadata,
    refund_metadata,
    transfer_metadata,
    source_relation

from balance_transaction_enhanced