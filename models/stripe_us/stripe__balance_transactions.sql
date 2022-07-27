with balance_transaction as (

    select *
    from {{ var('balance_transaction') }}

), charge as (

    select *
    from {{ var('charge')}}

), payment_intent as (

    select *
    from {{ var('payment_intent')}}

), cards as (

    select *
    from {{ var('card')}}

), payout as (

    select *
    from {{ var('payout')}}


), customer as (

    select *
    from {{ var('customer')}}

{% if var('using_payment_method', True) %}

), payment_method as (

    select *
    from {{ var('payment_method')}}

), payment_method_card as (

    select *
    from {{ var('payment_method_card')}}

{% endif %}

), refund as (

    select *
    from {{ var('refund')}}

)

select 
    balance_transaction.balance_transaction_id,
    balance_transaction.created_at,
    balance_transaction.available_on,
    balance_transaction.currency,
    balance_transaction.amount,
    balance_transaction.fee,
    balance_transaction.net,
    balance_transaction.type,
    case
        when balance_transaction.type in ('charge', 'payment') then 'charge'
        when balance_transaction.type in ('refund', 'payment_refund') then 'refund'
        when balance_transaction.type in ('payout_cancel', 'payout_failure') then 'payout_reversal'
        when balance_transaction.type in ('transfer', 'recipient_transfer') then 'transfer'
        when balance_transaction.type in ('transfer_cancel', 'transfer_failure', 'recipient_transfer_cancel', 'recipient_transfer_failure') then 'transfer_reversal'
        else balance_transaction.type
    end as reporting_category,
    balance_transaction.source,
    balance_transaction.description,
    case when balance_transaction.type = 'charge' then charge.amount end as customer_facing_amount, 
    case when balance_transaction.type = 'charge' then charge.currency end as customer_facing_currency,
    {{ dbt_utils.dateadd('day', 1, 'balance_transaction.available_on') }} as effective_at,
    coalesce(charge.customer_id, refund_charge.customer_id) as customer_id,
    charge.receipt_email,
    customer.description as customer_description, 

    {% if var('using_payment_method', True) %}
    payment_method.type as payment_method_type,
    payment_method_card.brand as payment_method_brand,
    payment_method_card.funding as payment_method_funding,
    {% endif %}

    charge.charge_id,
    charge.payment_intent_id,
    charge.created_at as charge_created_at,
    cards.brand as card_brand,
    cards.funding as card_funding,
    cards.country as card_country,
    payout.payout_id,
    payout.arrival_date as payout_expected_arrival_date,
    payout.status as payout_status,
    payout.type as payout_type,
    payout.description as payout_description,
    refund.reason as refund_reason
from balance_transaction

left join charge 
    on charge.balance_transaction_id = balance_transaction.balance_transaction_id
left join customer 
    on charge.customer_id = customer.customer_id
left join payment_intent 
    on charge.payment_intent_id = payment_intent.payment_intent_id

{% if var('using_payment_method', True) %}
left join payment_method 
    on payment_intent.payment_method_id = payment_method.payment_method_id
left join payment_method_card 
    on payment_method_card.payment_method_id = payment_method.payment_method_id
{% endif %}

left join cards 
    on charge.card_id = cards.card_id
left join payout 
    on payout.balance_transaction_id = balance_transaction.balance_transaction_id
left join refund 
    on refund.balance_transaction_id = balance_transaction.balance_transaction_id
left join charge as refund_charge 
    on refund.charge_id = refund_charge.charge_id
