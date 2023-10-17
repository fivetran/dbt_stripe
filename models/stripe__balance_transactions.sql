with balance_transaction as (

    select *
    from {{ var('balance_transaction') }}

), account as (

    select *
    from {{ var('account') }}

), cards as (

    select *
    from {{ var('card') }}

), charge as (
    
    select *
    from {{ var('charge') }}

), customer as (
    
    select *
    from {{ var('customer') }}

), dispute as (
    
    select *
    from {{ var('dispute') }}

{% if var('stripe__using_invoices', True) %}
), invoice as (
    
    select *
    from {{ var('invoice') }}

{% endif %}
), payment_intent as (
    
    select *
    from {{ var('payment_intent') }}

{% if var('stripe__using_payment_method', True) %}
), payment_method as (
    
    select *
    from {{ var('payment_method') }}

), payment_method_card as (

    select *
    from {{ var('payment_method_card')}}

{% endif %}
), payout as (
    
    select *
    from {{ var('payout') }}

), refund as (
    
    select *
    from {{ var('refund') }}

{% if var('stripe__using_subscriptions', True) %}
), subscription as (
    
    select *
    from {{ var('subscription') }}

{% endif %}
), transfers as (
    
    select *
    from {{ var('transfer') }}

)

select
    balance_transaction.balance_transaction_id,
    balance_transaction.created_at as balance_transaction_created_at,
    balance_transaction.available_on as balance_transaction_available_on,
    balance_transaction.currency as balance_transaction_currency,
    balance_transaction.amount as balance_transaction_amount,
    balance_transaction.fee as balance_transaction_fee,
    balance_transaction.net as balance_transaction_net,
    balance_transaction.source as source_id,
    balance_transaction.description as balance_transaction_description,
    balance_transaction.type as balance_transaction_type,
    coalesce(reporting_category,
        case
            when balance_transaction.type in ('charge', 'payment') then 'charge'
            when balance_transaction.type in ('refund', 'payment_refund') then 'refund'
            when balance_transaction.type in ('payout_cancel', 'payout_failure') then 'payout_reversal'
            when balance_transaction.type in ('transfer', 'recipient_transfer') then 'transfer'
            when balance_transaction.type in ('transfer_cancel', 'transfer_failure', 'recipient_transfer_cancel', 'recipient_transfer_failure') then 'transfer_reversal'
            else balance_transaction.type end)
    as reporting_category,
    case
        when balance_transaction.type in ('charge', 'payment') then charge.amount 
        when balance_transaction.type in ('refund', 'payment_refund') then refund.amount
        when dispute_id is not null then dispute.dispute_amount
        else null
    end as customer_facing_amount,
    case 
        when balance_transaction.type = 'charge' then charge.currency 
    end as customer_facing_currency,
    {{ dbt.dateadd('day', 1, 'balance_transaction.available_on') }} as effective_at,
    case
        when payout.is_automatic = true then payout.payout_id 
        else null
    end as automatic_payout_id,
    payout.payout_id,
    payout.created_at as payout_created_at,
    payout.currency as payout_currency,
    payout.is_automatic as payout_is_automatic,
    payout.arrival_date_at as payout_arrival_date_at,
    case
        when payout.is_automatic = true then payout.arrival_date_at
        else null
    end as automatic_payout_effective_at,
    payout.type as payout_type,
    payout.status as payout_status,
    payout.description as payout_description,
    payout.destination_bank_account_id,
    payout.destination_card_id,
    coalesce(charge.customer_id, refund_charge.customer_id) as customer_id,
    charge.receipt_email,
    customer.email as customer_email,
    customer.customer_name,
    customer.description as customer_description,
    customer.shipping_address_line_1 as customer_shipping_address_line_1,
    customer.shipping_address_line_2 as customer_shipping_address_line_2,
    customer.shipping_address_city as customer_shipping_address_city,
    customer.shipping_address_state as customer_shipping_address_state,
    customer.shipping_address_postal_code as customer_shipping_address_postal_code,
    customer.shipping_address_country as customer_shipping_address_country,
    customer.customer_address_line_1,
    customer.customer_address_line_2,
    customer.customer_address_city,
    customer.customer_address_state,
    customer.customer_address_postal_code,
    customer.customer_address_country,
    charge.shipping_address_line_1,
    charge.shipping_address_line_2,
    charge.shipping_address_city,
    charge.shipping_address_state,
    charge.shipping_address_postal_code,
    charge.shipping_address_country,
    cards.card_address_line_1,
    cards.card_address_line_2,
    cards.card_address_city,
    cards.card_address_state,
    cards.card_address_postal_code,
    cards.card_address_country,
    coalesce(charge.charge_id, refund.charge_id, dispute.charge_id) as charge_id,
    charge.created_at as charge_created_at,
    payment_intent.payment_intent_id,

    {% if var('stripe__using_invoices', True) %}
    invoice.invoice_id,
    invoice.number as invoice_number,
    {% endif %}

    {% if var('stripe__using_subscriptions', True) %}
    subscription.subscription_id,
    {% endif %}

    {% if var('stripe__using_payment_method', True) %}
    payment_method.type as payment_method_type,
    payment_method_card.brand as payment_method_brand,
    payment_method_card.funding as payment_method_funding,
    {% endif %}

    cards.brand as card_brand,
    cards.funding as card_funding,
    cards.country as card_country,
    charge.statement_descriptor,
    dispute.dispute_id,
    dispute.dispute_reason,
    refund.refund_id,
    refund.reason as refund_reason,
    transfers.transfer_id,
    coalesce(balance_transaction.connected_account_id, charge.connected_account_id) as connected_account_id,
    connected_account.country as connected_account_country,
    case 
        when charge.connected_account_id is not null then charge.charge_id
        else null
    end as connected_account_direct_charge_id,

    
    coalesce(payment_intent.metadata, charge.metadata) as payment_metadata,
    refund.metadata as refund_metadata,
    transfers.transfer_metadata,
    balance_transaction.source_relation

from balance_transaction

left join payout 
    on payout.balance_transaction_id = balance_transaction.balance_transaction_id
    and payout.source_relation = balance_transaction.source_relation
left join account connected_account
    on balance_transaction.connected_account_id = connected_account.account_id
    and balance_transaction.source_relation = connected_account.source_relation
left join charge
    on charge.balance_transaction_id = balance_transaction.balance_transaction_id
    and charge.source_relation = balance_transaction.source_relation
left join customer 
    on charge.customer_id = customer.customer_id
    and charge.source_relation = customer.source_relation
left join cards
    on charge.card_id = cards.card_id
    and charge.source_relation = cards.source_relation
left join payment_intent
    on charge.payment_intent_id = payment_intent.payment_intent_id
    and charge.source_relation = payment_intent.source_relation

{% if var('stripe__using_payment_method', True) %}
left join payment_method
    on charge.payment_method_id = payment_method.payment_method_id
    and charge.source_relation = payment_method.source_relation
left join payment_method_card 
    on payment_method_card.payment_method_id = payment_method.payment_method_id
    and charge.source_relation = balance_transaction.source_relation
{% endif %}

{% if var('stripe__using_invoices', True) %}
left join invoice 
    on charge.invoice_id = invoice.invoice_id
    and charge.source_relation = invoice.source_relation
{% endif %}

{% if var('stripe__using_subscriptions', True) %}
left join subscription
    on subscription.latest_invoice_id =  charge.invoice_id
    and subscription.source_relation =  charge.source_relation
{% endif %}

left join refund
    on refund.balance_transaction_id = balance_transaction.balance_transaction_id
    and refund.source_relation = balance_transaction.source_relation
left join transfers 
    on transfers.balance_transaction_id = balance_transaction.balance_transaction_id
    and transfers.source_relation = balance_transaction.source_relation
left join charge as refund_charge 
    on refund.charge_id = refund_charge.charge_id
    and refund.source_relation = refund_charge.source_relation
left join dispute
    on charge.charge_id = dispute.charge_id
    and charge.source_relation = dispute.source_relation

