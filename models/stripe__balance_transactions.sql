{% set charge_cols = adapter.get_columns_in_relation(ref('stg_stripe__charge')) | map(attribute='name') | list %}
{% set invoice_cols = adapter.get_columns_in_relation(ref('stg_stripe__invoice')) | map(attribute='name') | list %}
{% set subscription_cols = adapter.get_columns_in_relation(ref('stg_stripe__subscription')) | map(attribute='name') | list %}
{% set customer_cols = adapter.get_columns_in_relation(ref('stg_stripe__customer')) | map(attribute='name') | list %}

with balance_transaction as (

    select *
    from {{ ref('stg_stripe__balance_transaction') }}

), account as (

    select *
    from {{ ref('stg_stripe__account') }}

), cards as (

    select *
    from {{ ref('stg_stripe__card') }}

), charge as (
    
   select
      charge.*
      {% for metadata in var('stripe__charge_metadata', []) %}
        {% if metadata in charge_cols %}
          , charge.{{ metadata }} as charge_{{ metadata }}
        {% else %}
        {% endif %}
      {% endfor %}
   from {{ ref('stg_stripe__charge') }} as charge

), customer as (

   select
      customer.*
      {% for metadata in var('stripe__customer_metadata', []) %}
        {% if metadata in customer_cols %}
          , customer.{{ metadata }} as customer_{{ metadata }}
        {% else %}
        {% endif %}
      {% endfor %}
   from {{ ref('stg_stripe__customer') }} as customer

), dispute as (

    select *
    from {{ ref('stg_stripe__dispute') }}

{% if var('stripe__using_invoices', True) %}
        {% endif %}
      {% endfor %}
   from {{ ref('stg_stripe__invoice') }} as invoice

), dispute as (
    
    select *
    from {{ ref('stg_stripe__dispute') }}

{% if var('stripe__using_invoices', True) %}
), invoice as (

   select
      invoice.*
      {% for metadata in var('stripe__invoice_metadata', []) %}
        {% if metadata in invoice_cols %}
          , invoice.{{ metadata }} as invoice_{{ metadata }}
        {% else %}
        {% endif %}
      {% endfor %}
   from {{ ref('stg_stripe__invoice') }} as invoice

{% endif %}
), payment_intent as (
    
    select *
    from {{ ref('stg_stripe__payment_intent') }}

{% if var('stripe__using_payment_method', True) %}
), payment_method as (
    
    select *
    from {{ ref('stg_stripe__payment_method') }}

), payment_method_card as (

    select *
    from {{ ref('stg_stripe__payment_method_card') }}

{% endif %}

{% if var('stripe__using_payouts', True) %}
), payout as (

    select *
    from {{ ref('stg_stripe__payout') }}

), payout_balance_transaction as (

    select *
    from {{ ref('stg_stripe__payout_balance_transaction') }}

), payout_balance_transaction_unified as (
    -- Create a unified mapping table to bridge records without mapping.
    select
        balance_transaction.source_relation,
        balance_transaction.balance_transaction_id,
        coalesce(payout_balance_transaction.payout_id, payout.payout_id) as payout_id
    from balance_transaction

    left join payout_balance_transaction
        on payout_balance_transaction.balance_transaction_id = balance_transaction.balance_transaction_id
        and payout_balance_transaction.source_relation = balance_transaction.source_relation
    left join payout
        on payout.balance_transaction_id = balance_transaction.balance_transaction_id
        and payout.source_relation = balance_transaction.source_relation

{% endif %}

), refund as (
    
    select *
    from {{ ref('stg_stripe__refund') }}

{% if var('stripe__using_subscriptions', True) %}
), subscription as (

    select
      subscription.*
      {% for metadata in var('stripe__subscription_metadata', []) %}
        {% if metadata in subscription_cols %}
          , subscription.{{ metadata }} as subscription_{{ metadata }}
        {% else %}
        {% endif %}
      {% endfor %}
   from {{ ref('stg_stripe__subscription') }} as subscription

{% endif %}

{% if var('stripe__using_transfers', True) %}    
), transfers as (

    select *
    from {{ ref('stg_stripe__transfer') }}

{% endif %}

), dispute_summary as (
    /* Although rare, payments can be disputed multiple times. 
    Hence, we need to aggregate the disputes to get the total disputed amount.
    */
    select
        charge_id,
        source_relation,
        {{ fivetran_utils.string_agg('dispute_id', "','")}} as dispute_ids,
        {{ fivetran_utils.string_agg('distinct dispute_reason', "','")}} as dispute_reasons,
        count(dispute_id) as dispute_count
    from dispute
    group by 1,2

), order_disputes as (

    select 
        charge_id,
        source_relation,
        dispute_id,
        dispute_status,
        dispute_amount,
        row_number() over (partition by charge_id, dispute_status, source_relation order by dispute_created_at desc) = 1 as is_latest_status_dispute,
        row_number() over (partition by charge_id, source_relation order by dispute_created_at desc, dispute_amount desc) = 1 as is_absolute_latest_dispute -- include dispute_amount desc in off chance of identical dispute_created_ats 
    from dispute 

), latest_disputes as (

    select 
        charge_id,
        source_relation,
        -- Iterate over each type of possible status (according https://docs.stripe.com/api/disputes/object) and pull out the dispute_amount from the latest dispute
        {% for status in ['won', 'lost', 'under_review', 'needs_response', 'warning_closed', 'warning_under_review', 'warning_needs_response'] %}
            sum(case when lower(dispute_status) = '{{ status }}' then dispute_amount else 0 end) as latest_dispute_amount_{{ status }},
        {% endfor %}
        -- For the customer_facing_amount fields, pull out the generally latest dispute_amount
        sum(case when is_absolute_latest_dispute then dispute_amount else 0 end) as latest_dispute_amount

    from order_disputes 
    where is_latest_status_dispute
    group by 1,2
)

select
    balance_transaction.balance_transaction_id,
    balance_transaction.created_at as balance_transaction_created_at,
    balance_transaction.available_on as balance_transaction_available_on,
    balance_transaction.currency as balance_transaction_currency,
    balance_transaction.amount as balance_transaction_amount,
    balance_transaction.fee as balance_transaction_fee,
    balance_transaction.net as balance_transaction_net,
    balance_transaction.source as balance_transaction_source_id,
    balance_transaction.description as balance_transaction_description,
    balance_transaction.type as balance_transaction_type,
    coalesce(balance_transaction.reporting_category,
        case
            when balance_transaction.type in ('charge', 'payment') then 'charge'
            when balance_transaction.type in ('refund', 'payment_refund') then 'refund'
            when balance_transaction.type in ('payout_cancel', 'payout_failure') then 'payout_reversal'
            when balance_transaction.type in ('transfer', 'recipient_transfer') then 'transfer'
            when balance_transaction.type in ('transfer_cancel', 'transfer_failure', 'recipient_transfer_cancel', 'recipient_transfer_failure') then 'transfer_reversal'
            else balance_transaction.type end)
    as balance_transaction_reporting_category,
    case
        when balance_transaction.type in ('charge', 'payment') then charge.amount 
        when balance_transaction.type in ('refund', 'payment_refund') then refund.amount
        when dispute_ids is not null then latest_disputes.latest_dispute_amount
        else null
    end as customer_facing_amount,
    case 
        when balance_transaction.type = 'charge' then charge.currency 
    end as customer_facing_currency,
    latest_disputes.latest_dispute_amount_won,
    latest_disputes.latest_dispute_amount_lost,
    latest_disputes.latest_dispute_amount_under_review,
    latest_disputes.latest_dispute_amount_needs_response,
    latest_disputes.latest_dispute_amount_warning_closed,
    latest_disputes.latest_dispute_amount_warning_under_review,
    latest_disputes.latest_dispute_amount_warning_needs_response,
    {{ dbt.dateadd('day', 1, 'balance_transaction.available_on') }} as effective_at,
    {% if var('stripe__using_payouts', True) %}
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
    -- Checks if this balance transaction matches the most recent balance_transaction_id recorded in PAYOUT.
    payout_balance_transaction_unified.balance_transaction_id = payout.balance_transaction_id as payout_balance_transaction_is_current,
    {% else %}
    null as automatic_payout_id,
    null as payout_id,
    null as payout_created_at,
    null as payout_currency,
    null as payout_is_automatic,
    null as payout_arrival_date_at,
    null as automatic_payout_effective_at,
    null as payout_type,
    null as payout_status,
    null as payout_description,
    null as destination_bank_account_id,
    null as destination_card_id,
    null as payout_balance_transaction_is_current,
    {% endif %}
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
    {% for metadata in var('stripe__customer_metadata', []) %}
      {% if metadata in customer_cols %}
        customer.customer_{{ metadata }} as customer_{{ metadata }},
      {% endif %}
    {% endfor %}
    charge.shipping_address_line_1 as charge_shipping_address_line_1,
    charge.shipping_address_line_2 as charge_shipping_address_line_2,
    charge.shipping_address_city as charge_shipping_address_city,
    charge.shipping_address_state as charge_shipping_address_state,
    charge.shipping_address_postal_code as charge_shipping_address_postal_code,
    charge.shipping_address_country as charge_shipping_address_country,
    cards.card_address_line_1,
    cards.card_address_line_2,
    cards.card_address_city,
    cards.card_address_state,
    cards.card_address_postal_code,
    cards.card_address_country,
    coalesce(charge.charge_id, refund.charge_id, dispute_summary.charge_id) as charge_id,
    charge.created_at as charge_created_at,
    {% for metadata in var('stripe__charge_metadata', []) %}
      {% if metadata in charge_cols %}
        charge.charge_{{ metadata }} as charge_{{ metadata }},
      {% endif %}
    {% endfor %}

    payment_intent.payment_intent_id,

    {% if var('stripe__using_invoices', True) %}
    invoice.invoice_id,
    invoice.number as invoice_number,
    {% for metadata in var('stripe__invoice_metadata', []) %}
      {% if metadata in invoice_cols %}
        invoice.invoice_{{ metadata }} as invoice_{{ metadata }},
      {% endif %}
    {% endfor %}
    {% endif %}

    {% if var('stripe__using_subscriptions', True) %}
    subscription.subscription_id,
    {% for metadata in var('stripe__subscription_metadata', []) %}
      {% if metadata in subscription_cols %}
        subscription.subscription_{{ metadata }} as subscription_{{ metadata }},t
      {% endif %}
    {% endfor %}
    {% endif %}

    {% if var('stripe__using_payment_method', True) %}
    payment_method.type as payment_method_type,
    payment_method_card.brand as payment_method_brand,
    payment_method_card.funding as payment_method_funding,
    {% endif %}

    cards.brand as card_brand,
    cards.funding as card_funding,
    cards.country as card_country,
    charge.statement_descriptor as charge_statement_descriptor,
    dispute_summary.dispute_ids,
    dispute_summary.dispute_reasons,
    dispute_summary.dispute_count,
    refund.refund_id,
    refund.reason as refund_reason,
    {% if var('stripe__using_transfers', True) %}
    transfers.transfer_id,
    {% else %}
    null as transfer_id,
    {% endif %}
    coalesce(balance_transaction.connected_account_id, charge.connected_account_id) as connected_account_id,
    connected_account.country as connected_account_country,
    case 
        when charge.connected_account_id is not null then charge.charge_id
        else null
    end as connected_account_direct_charge_id,
    balance_transaction.source_relation

from balance_transaction

{% if var('stripe__using_payouts', True) %}
left join payout_balance_transaction_unified
    on payout_balance_transaction_unified.balance_transaction_id = balance_transaction.balance_transaction_id
    and payout_balance_transaction_unified.source_relation = balance_transaction.source_relation
left join payout
    on payout.payout_id = payout_balance_transaction_unified.payout_id
    and payout.source_relation = payout_balance_transaction_unified.source_relation
{% endif %}

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

{% if var('stripe__using_transfers', True) %}
left join transfers
    on transfers.balance_transaction_id = balance_transaction.balance_transaction_id
    and transfers.source_relation = balance_transaction.source_relation
{% endif %}

left join charge as refund_charge 
    on refund.charge_id = refund_charge.charge_id
    and refund.source_relation = refund_charge.source_relation
left join dispute_summary
    on charge.charge_id = dispute_summary.charge_id
    and charge.source_relation = dispute_summary.source_relation
left join latest_disputes
    on charge.charge_id = latest_disputes.charge_id
    and charge.source_relation = latest_disputes.source_relation