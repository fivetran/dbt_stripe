with balance_transactions_joined as (

    select *
    from {{ ref('stripe_balance_transaction_joined') }}  

)

select 
  balance_transaction_id,
  created_at,
  available_on,
  currency,
  amount,
  fee,
  net,
  type,
  reporting_category,
  source,
  description,
  customer_facing_amount,
  customer_facing_currency,
  payout_id,
  effective_at,
  customer_id,
  receipt_email,
  customer_description,
  charge_id,
  payment_intent_id,
  charge_created_at,
  payment_method_type,
  card_brand,
  card_funding,
  card_country,
  paytout_id,
  payout_expeted_arrival_date,
  payout_status,
  payout_type,
  payout_description,
  payout_destination_id,
  refund_reason
from balance_transaction_joined