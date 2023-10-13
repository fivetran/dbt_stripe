with balance_transaction as (

    select 
        balance_transaction_id,
        connected_account_id,
        created_at as balance_transaction_created_at,
        available_on as balance_transaction_available_on, 
        currency as balance_transaction_currency, 
        amount as balance_transaction_amount, 
        fee as balance_transaction_fee, 
        net as balance_transaction_net,
        reporting_category,
        source as source_id,
        status as balance_transaction_status,
        type as balance_transaction_type,
        description as balance_transaction_description,
        source_relation

    from {{ var('balance_transaction') }}

), account as (

    select
        account_id,
        business_profile_mcc,
        business_profile_name,
        business_type,
        charges_enabled,
        company_address_city,
        company_address_country,
        company_address_line_1,
        company_address_line_2,
        company_address_postal_code,
        company_address_state,
        company_name,
        company_phone,
        country as account_country,
        created_at as account_created_at,
        default_currency,
        email,
        is_deleted,
        metadata as account_metadata,
        is_payouts_enabled,
        account_type,
        source_relation

    from {{ var('account') }}

), cards as (

    select
        card_id,
        account_id,
        card_address_city,
        card_address_country,
        card_address_line_1,
        card_address_line_2,
        card_address_state,
        card_address_postal_code,
        wallet_type,
        brand as card_brand,
        country as card_country,
        created_at as card_created_at,
        customer_id,
        card_name,
        recipient,
        funding as card_funding,
        source_relation

    from {{ var('card') }}

), charge as (
    
    select
        charge_id,
        amount as charge_amount,
        amount_refunded,
        application_fee_amount,
        balance_transaction_id,
        is_captured,
        card_id,
        created_at as charge_created_at,
        connected_account_id,
        customer_id,
        currency as charge_currency,
        description,
        failure_code,
        failure_message,
        metadata as charge_metadata,
        is_paid,
        payment_intent_id,
        payment_method_id,
        receipt_email,
        receipt_number,
        is_refunded,
        status,
        shipping_address_city,
        shipping_address_country,
        shipping_address_line_1,
        shipping_address_line_2,
        shipping_address_postal_code,
        shipping_address_state,
        shipping_carrier,
        shipping_name,
        shipping_phone,
        shipping_tracking_number,
        source_id,
        source_transfer,
        statement_descriptor,
        invoice_id,
        calculated_statement_descriptor,
        billing_detail_address_city,
        billing_detail_address_country,
        billing_detail_address_line1,
        billing_detail_address_line2,
        billing_detail_address_postal_code,
        billing_detail_address_state,
        billing_detail_email,
        billing_detail_name,
        billing_detail_phone,
        source_relation

    from {{ var('charge') }}

), customer as (
    
    select
        customer_id,
        account_balance as customer_account_balance,
        customer_address_city,
        customer_address_country,
        customer_address_line_1,
        customer_address_line_2,
        customer_address_postal_code,
        customer_address_state,
        customer_balance,
        bank_account_id,
        created_at as customer_created_at,
        currency,
        default_card_id,
        is_delinquent,
        description as customer_description,
        email as customer_email,
        customer_name,
        metadata as customer_metadata,
        shipping_address_city as customer_shipping_address_city,
        shipping_address_country as customer_shipping_address_country,
        shipping_address_line_1 as customer_shipping_address_line_1,
        shipping_address_line_2 as customer_shipping_address_line_2,
        shipping_address_postal_code as customer_shipping_address_postal_code,
        shipping_address_state as customer_shipping_address_state,
        shipping_name as customer_shipping_name,
        shipping_phone as customer_shipping_phone,
        source_relation
    
    from {{ var('customer') }}

), dispute as (
    
    select
        dispute_id,
        dispute_amount,
        balance_transaction,
        charge_id,
        connected_account_id,
        dispute_created_at,
        dispute_currency,
        dispute_reason,
        dispute_status,
        dispute_metadata,
        source_relation
    
    from {{ var('dispute') }}


{% if var('stripe__using_invoices', True) %}
), invoice as (
    
    select
        invoice_id,
        default_payment_method_id,
        payment_intent_id,
        subscription_id,
        amount_due,
        amount_paid,
        amount_remaining,
        post_payment_credit_notes_amount,
        pre_payment_credit_notes_amount,
        attempt_count,
        auto_advance,
        billing_reason,
        charge_id,
        created_at as invoice_created_at,
        currency,
        customer_id,
        description,
        due_date,
        metadata as invoice_metadata,
        number as invoice_number,
        is_paid,
        receipt_number,
        status,
        subtotal,
        tax,
        tax_percent,
        total,
        period_start,
        period_end,
        status_transitions_finalized_at,
        status_transitions_marked_uncollectible_at,
        status_transitions_paid_at,
        status_transitions_voided_at,
        source_relation
    
    from {{ var('invoice') }}

{% endif %}

), payment_intent as (
    
    select
        payment_intent_id,
        amount,
        amount_capturable,
        amount_received,
        application,
        application_fee_amount,
        canceled_at,
        cancellation_reason,
        capture_method,
        confirmation_method,
        created_at as payment_intent_created_at,
        currency,
        customer_id,
        description,
        metadata as payment_intent_metadata,
        payment_method_id,
        receipt_email,
        statement_descriptor,
        status,
        source_relation

    from {{ var('payment_intent') }}

{% if var('stripe__using_payment_method', True) %}
), payment_method as (
    
    select
        payment_method_id,
        created_at as payment_method_created_at,
        customer_id,
        metadata as payment_method_metadata,
        type as payment_method_type,
        source_relation
    
    from {{ var('payment_method') }}

), payment_method_card as (

    select *
    from {{ var('payment_method_card')}}

{% endif %}

), payout as (
    
    select
        payout_id,
        amount as payout_amount,
        arrival_date_at as payout_arrival_date_at,
        is_automatic,
        balance_transaction_id,
        created_at as payout_created_at,
        currency as payout_currency,
        description as payout_description,
        destination_bank_account_id,
        destination_card_id,
        metadata as payout_metadata,
        method as payout_method,
        source_type,
        status as payout_status,
        type as payout_type,
        source_relation

    from {{ var('payout') }}

), refund as (
    
    select
        refund_id,
        payment_intent_id,
        balance_transaction_id,
        charge_id,
        amount as refund_amount,
        created_at as refund_created_at,
        currency,
        description as refund_description,
        metadata as refund_metadata,
        reason as refund_reason,
        receipt_number,
        status as refund_status,
        source_relation

    from {{ var('refund') }}

{% if var('stripe__using_subscriptions', True) %}
), subscription as (
    
    select
        subscription_id,
        latest_invoice_id,
        customer_id,
        default_payment_method_id,
        pending_setup_intent_id,
        status,
        billing,
        billing_cycle_anchor,
        cancel_at,
        is_cancel_at_period_end,
        canceled_at,
        created_at as subscription_created_at,
        current_period_start,
        current_period_end,
        days_until_due,
        metadata as subscription_metadata,
        start_date_at,
        ended_at,
        pause_collection_behavior,
        pause_collection_resumes_at,
        source_relation

    from {{ var('subscription') }}

{% endif %}

), transfers as (
    
    select
        transfer_id,
        transfer_amount,
        transfer_amount_reversed,
        balance_transaction_id,
        transfer_created_at,
        transfer_currency,
        transfer_description, 
        transfer_destination,
        destination_payment,
        destination_payment_id,
        transfer_is_reversed,
        source_transaction,
        source_transaction_id,
        source_type,
        transfer_metadata,
        source_relation

    from {{ var('transfer') }}

)

select
    balance_transaction.balance_transaction_id,
    balance_transaction.balance_transaction_created_at,
    balance_transaction.balance_transaction_available_on,
    balance_transaction.balance_transaction_currency,
    balance_transaction.balance_transaction_amount,
    balance_transaction.balance_transaction_fee,
    balance_transaction.balance_transaction_net,
    balance_transaction.source_id as balance_transaction_source_id,
    balance_transaction.balance_transaction_description,
    balance_transaction.balance_transaction_type,
    coalesce(reporting_category,
        case
            when balance_transaction.balance_transaction_type in ('charge', 'payment') then 'charge'
            when balance_transaction.balance_transaction_type in ('refund', 'payment_refund') then 'refund'
            when balance_transaction.balance_transaction_type in ('payout_cancel', 'payout_failure') then 'payout_reversal'
            when balance_transaction.balance_transaction_type in ('transfer', 'recipient_transfer') then 'transfer'
            when balance_transaction.balance_transaction_type in ('transfer_cancel', 'transfer_failure', 'recipient_transfer_cancel', 'recipient_transfer_failure') then 'transfer_reversal'
            else balance_transaction.balance_transaction_type end)
    as balance_transactions_reporting_category,
    case 
        when balance_transaction.balance_transaction_type in ('charge', 'payment') then charge.charge_amount 
        when balance_transaction.balance_transaction_type in ('refund', 'payment_refund') then refund.refund_amount
        when dispute_id is not null then dispute.dispute_amount
        else null
    end as customer_facing_amount,
    case 
        when balance_transaction.balance_transaction_type = 'charge' then charge.charge_currency 
    end as customer_facing_currency,
    {{ dbt.dateadd('day', 1, 'balance_transaction_available_on') }} as effective_at,
    case
        when payout.is_automatic = true then payout.payout_id 
        else null
    end as automatic_payout_id,
    payout.payout_id,
    payout.payout_arrival_date_at as payout_expected_arrival_date,
    case
        when payout.is_automatic = true then payout.payout_arrival_date_at
        else null
    end as automatic_payout_effective_at,
    payout.payout_type,
    payout.payout_status,
    payout.payout_description,
    coalesce(charge.customer_id, refund_charge.customer_id) as customer_id,
    charge.receipt_email,
    customer.customer_email,
    customer.customer_name,
    customer.customer_description,
    customer.customer_shipping_address_line_1,
    customer.customer_shipping_address_line_2,
    customer.customer_shipping_address_city,
    customer.customer_shipping_address_state,
    customer.customer_shipping_address_postal_code,
    customer.customer_shipping_address_country,
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
    charge.charge_created_at,
    payment_intent.payment_intent_id,

    {% if var('stripe__using_invoices', True) %}
    invoice.invoice_id,
    invoice.invoice_number,
    {% endif %}

    {% if var('stripe__using_subscriptions', True) %}
    subscription.subscription_id,
    {% endif %}

    {% if var('stripe__using_payment_method', True) %}
    payment_method.payment_method_type,
    payment_method_card.brand as payment_method_brand,
    payment_method_card.funding as payment_method_funding,
    {% endif %}

    cards.card_brand,
    cards.card_funding,
    cards.card_country,
    charge.statement_descriptor,
    dispute.dispute_id,
    dispute.dispute_reason,
    refund.refund_id,
    refund.refund_reason,
    transfers.transfer_id,
    coalesce(balance_transaction.connected_account_id, charge.connected_account_id) as connected_account_id, 
    connected_account.account_name as connected_account_name,
    connected_account.account_country as connected_account_country,
    case 
        when charge.connected_account_id is not null then charge.charge_id
        else null
    end as connected_account_direct_charge_id,
    coalesce(payment_intent.payment_intent_metadata, charge.charge_metadata) as payment_metadata,
    refund.refund_metadata,
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

