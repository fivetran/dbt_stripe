with balance_transaction as (

    select *
    from {{ ref('stg_stripe_balance_transaction') }}
  
), charge as (

    select *
    from {{ ref('stg_stripe_charge')}}

), payment_intent as (

    select *
    from {{ ref('stg_stripe_payment_intent')}}

), payment_method as (

    select *
    from {{ ref('stg_stripe_payment_method')}}

), payment_method as (

    select *
    from {{ ref('stg_stripe_payment_method')}}

), card as (

    select *
    from {{ ref('stg_stripe_card')}}

), payout as (

    select *
    from {{ ref('stg_stripe_payout')}}

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
    when balance_transaction.type in ('payout_cancel', 'payout_failure')	then 'payout_reversal'
    when balance_transaction.type in ('transfer', 'recipient_transfer') then	'transfer'
    when balance_transaction.type in ('transfer_cancel', 'transfer_failure', 'recipient_transfer_cancel', 'recipient_transfer_failure') then 'transfer_reversal'
    else balance_transaction.type
  end as reporting_category,
  balance_transaction.source,
  balance_transaction.description,
  case when balance_transaction.type = 'charge' then charge.amount end as customer_facing_amount, --think this might be the charge amount/currency
  case when balance_transaction.type = 'charge' then charge.currency end as customer_facing_currency,
  balance_transaction.payout_id,
  date_add(date(balance_transaction.available_on), interval 1 day) as effective_at,
  charge.customer_id,
  charge.receipt_email,
  customer.description as customer_description,
  charge.id as charge_id,
  charge.payment_intent_id,
  charge.created as charge_created,
  payment_method.type as payment_method_type,
  card.brand as card_brand,
  card.funding as card_funding,
  card.country as card_country,
  payout.id as paytout_id,
  payout.arrival_date as payout_expeted_arrival_date,
  payout.status as payout_status,
  payout.type as payout_type,
  payout.description as payout_description,
  payout.destination_bank_account_id as payout_destination_id
from balance_transaction
left join charge on charge.balance_transaction_id = balance_transaction.balance_trasnaction_id
left join customer on charge.customer_id = customer.id
left join payment_intent on charge.payment_intent_id = payment_intent.id
left join payment_method on payment_intent.payment_method_id = payment_method.id
left join card on charge.card_id = card.id
left join payout on payout.balance_transaction_id = balance_transaction.balance_transaction_id
order by created desc
;
