with balance_transaction as (

    select 
        balance_transaction_id, 
        connected_account_id,
        created_at,
        available_on, 
        currency, 
        amount, 
        fee, 
        net, 
        reporting_category, 
        source as source_id,
        status,
        type,
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

), card as (

    select
        card_id,
        account_id,
        card_address_city,
        card_address_country,
        card_address_line_1,
        card_address_line_1_check,
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
        name as customer_name,
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

), dispute as 

    (select
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

), invoice as 

    (select
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
        cast(status_transitions_finalized_at as TIMESTAMP) as status_transitions_finalized_at,
        cast(status_transitions_marked_uncollectible_at as TIMESTAMP) as status_transitions_marked_uncollectible_at,
        cast(status_transitions_paid_at as TIMESTAMP) as status_transitions_paid_at,
        cast(status_transitions_voided_at as TIMESTAMP) as status_transitions_voided_at,
        source_relation
    
    from {{ var('invoice') }}

), payment_intent as 

    (select 
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

), payment_method as 

    (select
        payment_method_id,
        created_at as payment_method_created_at,
        customer_id,
        metadata as payment_method_metadata,
        type as payment_method_type,
        source_relation
    
    from {{ var('payment_method') }}

), payout as 

    (select
        payout_id,
        amount,
        arrival_date,
        is_automatic,
        balance_transaction_id,
        created_at as payout_created_at,
        currency,
        description,
        metadata as payout_metadata,
        method,
        source_type,
        status,
        type as payout_type,
        source_relation

    from {{ var('payout') }}

), refund as 

    (select
        refund_id,
        payment_intent_id,
        balance_transaction_id,
        charge_id,
        amount,
        created_at as refund_created_at,
        currency,
        description,
        metadata as refund_metadata,
        reason,
        receipt_number,
        status,
        source_relation

    from {{ var('refund') }}

), subscription as 

    (select 
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

), transfers as 

    (select
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
    balance_transaction.created_at,
    balance_transaction.available_on,
    balance_transaction.currency,
    balance_transaction.amount,
    balance_transaction.fee,
    balance_transaction.net,
    balance_transaction.reporting_category,
    balance_transaction.source_id,
    balance_transaction.balance_transaction_description,
    case 
        when balance_transaction.reporting_category = 'charge' or balance_transaction.type = 'refund' then charge.charge_amount 
        end as customer_facing_amount,
    case 
        when balance_transaction.type = 'charge' then charge.charge_currency 
    end as customer_facing_currency,
    case 
        when payout.is_automatic is true then payout.payout_id
    end as automatic_payout_id,
    payout.arrival_date as automatic_payout_effective_at,
    coalesce(charge.customer_id, refund_charge.customer_id) as customer_id,
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
    card.card_address_line_1,
    card.card_address_line_2,
    card.card_address_city,
    card.card_address_state,
    card.card_address_postal_code,
    card.card_address_country,
    charge.charge_id,
    charge.payment_intent_id,
    charge.charge_created_at,
    invoice.invoice_id,
    invoice.invoice_number,
    subscription.subscription_id,


    {% if var('stripe__using_payment_method', True) %}
    payment_method.payment_method_type,
    {% endif %}

    card.card_brand,
    card.card_funding,
    card.card_country,
    charge.statement_descriptor,
    dispute.dispute_id,
    dispute.dispute_reason,
    refund.refund_id,
    transfers.transfer_id,
    coalesce(balance_transaction.connected_account_id, charge.connected_account_id) as connected_account_id, 
    connected_account.account_country as connected_account_country,
    case 
        when charge.connected_account_id is not null then charge.charge_id
    end as connected_account_direct_charge_id,
    coalesce(payment_intent.payment_intent_metadata, charge.charge_metadata) as payment_metadata,
    refund.refund_metadata,
    transfers.transfer_metadata



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
left join card
    on charge.card_id = card.card_id
    and charge.source_relation = card.source_relation
left join payment_intent
    on charge.payment_intent_id = payment_intent.payment_intent_id
    and charge.source_relation = payment_intent.source_relation


{% if var('stripe__using_payment_method', True) %}
left join payment_method
    on charge.payment_method_id = payment_method.payment_method_id
    and charge.source_relation = payment_method.source_relation
{% endif %}

left join invoice 
    on charge.invoice_id = invoice.invoice_id
    and charge.source_relation = invoice.source_relation
left join subscription
    on subscription.latest_invoice_id =  invoice.invoice_id
    and subscription.source_relation =  invoice.source_relation
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

