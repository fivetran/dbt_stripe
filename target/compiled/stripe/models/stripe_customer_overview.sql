with  __dbt__CTE__stg_stripe_balance_transaction as (
with balance_transaction as (

    select *
    from `dbt-package-testing`.`stripe`.`balance_transaction`

), fields as (

    select 
      id as balance_transaction_id,
      amount,
      available_on,
      created as created_at,
      currency,
      description,
      exchange_rate,
      fee,
      net,
      source,
      status,
      type
    from balance_transaction
)

select *
from fields
),  __dbt__CTE__stg_stripe_charge as (
with charge as (

    select *
    from `dbt-package-testing`.`stripe`.`charge`

), fields as (

    select 
      id as charge_id, 
      amount,
      amount_refunded,
      application_fee_amount,
      balance_transaction_id,
      captured as is_captured,
      card_id,
      created as created_at,
      customer_id,
      currency,
      description,
      failure_code,
      failure_message,
      paid as is_paid,
      payment_intent_id,
      receipt_email,
      receipt_number,
      refunded as is_refunded,
      status,
      invoice_id
    from charge
    
)

select *
from fields
),  __dbt__CTE__stg_stripe_payment_intent as (
with payment_intent as (

    select *
    from `dbt-package-testing`.`stripe`.`payment_intent`

), fields as (

    select 
      id as payment_intent_id,
      amount,
      amount_capturable,
      amount_received,
      application,
      application_fee_amount,
      canceled_at,
      cancellation_reason,
      capture_method,
      confirmation_method,
      created as created_at,
      currency,
      customer_id,
      description,
      payment_method_id,
      receipt_email,
      statement_descriptor,
      status
    from payment_intent

)

select *
from fields
),  __dbt__CTE__stg_stripe_payment_method as (
with payment_method as (

    select *
    from `dbt-package-testing`.`stripe`.`payment_method`

), fields as (

    select 
      id as payment_method_id,
      created as created_at,
      customer_id,
      type
    from payment_method
    where not is_deleted

)

select *
from fields
),  __dbt__CTE__stg_stripe_card as (
with card as (

    select *
    from `dbt-package-testing`.`stripe`.`card`

), fields as (

    select 
      id as card_id,
      brand,
      country,
      created as created_at,
      customer_id,
      name,
      recipient,
      funding
    from card
    where not coalesce(is_deleted, false)

)

select *
from fields
),  __dbt__CTE__stg_stripe_payout as (
with payout as (

    select *
    from `dbt-package-testing`.`stripe`.`payout`

), fields as (

    select 
      id as payout_id,
      amount,
      arrival_date,
      automatic as is_automatic,
      balance_transaction_id,
      created as created_at,
      currency,
      description,
      method,
      source_type,
      status,
      type
    from payout

)

select *
from fields
),  __dbt__CTE__stg_stripe_refund as (
with refund as (

    select *
    from `dbt-package-testing`.`stripe`.`refund`

), fields as (

    select 
      id as refund_id,
      amount,
      balance_transaction_id,
      charge_id,
      created as created_at,
      currency,
      description,
      reason,
      receipt_number,
      status
    from refund

)

select *
from fields
),  __dbt__CTE__stg_stripe_customer as (
with customer as (

    select *
    from `dbt-package-testing`.`stripe`.`customer`

), fields as (

    select 
      id as customer_id,
      account_balance,
      created as created_at,
      currency,
      default_card_id,
      delinquent as is_deliguent,
      description,
      email,
      shipping_address_city,
      shipping_address_country,
      shipping_address_line_1,
      shipping_address_line_2,
      shipping_address_postal_code,
      shipping_address_state,
      shipping_name,
      shipping_phone
    from customer
    where not is_deleted

)

select *
from fields
),  __dbt__CTE__stripe_balance_transaction_joined as (
with balance_transaction as (

    select *
    from __dbt__CTE__stg_stripe_balance_transaction
  
), charge as (

    select *
    from __dbt__CTE__stg_stripe_charge

), payment_intent as (

    select *
    from __dbt__CTE__stg_stripe_payment_intent

), payment_method as (

    select *
    from __dbt__CTE__stg_stripe_payment_method

), card as (

    select *
    from __dbt__CTE__stg_stripe_card

), payout as (

    select *
    from __dbt__CTE__stg_stripe_payout

), refund as (

    select *
    from __dbt__CTE__stg_stripe_refund

), customer as (

    select *
    from __dbt__CTE__stg_stripe_customer


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
  date_add(date(balance_transaction.available_on), interval 1 day) as effective_at,
  coalesce(charge.customer_id, refund_charge.customer_id) as customer_id,
  charge.receipt_email,
  customer.description as customer_description,
  charge.charge_id,
  charge.payment_intent_id,
  charge.created_at as charge_created_at,
  payment_method.type as payment_method_type,
  card.brand as card_brand,
  card.funding as card_funding,
  card.country as card_country,
  payout.payout_id,
  payout.arrival_date as payout_expeted_arrival_date,
  payout.status as payout_status,
  payout.type as payout_type,
  payout.description as payout_description,
  refund.reason as refund_reason
from balance_transaction
left join charge on charge.balance_transaction_id = balance_transaction.balance_transaction_id
left join customer on charge.customer_id = customer.customer_id
left join payment_intent on charge.payment_intent_id = payment_intent.payment_intent_id
left join payment_method on payment_intent.payment_method_id = payment_method.payment_method_id
left join card on charge.card_id = card.card_id
left join payout on payout.balance_transaction_id = balance_transaction.balance_transaction_id
left join refund on refund.balance_transaction_id = balance_transaction.balance_transaction_id
left join charge as refund_charge on refund.charge_id = refund_charge.charge_id
order by created_at desc
),  __dbt__CTE__stripe_incomplete_charges as (
with charge as (

    select *
    from __dbt__CTE__stg_stripe_charge

)

select 
  created_at,
  customer_id,
  amount
from charge
where not is_captured
),balance_transaction_joined as (

    select *
    from __dbt__CTE__stripe_balance_transaction_joined  

), incomplete_charges as (

    select *
    from __dbt__CTE__stripe_incomplete_charges  

), customer as (

    select *
    from __dbt__CTE__stg_stripe_customer  

), transactions_grouped as (
 
    select
      customer_id,
      sum(if(type in ('charge', 'payment'), amount, 0)) as total_sales,
      sum(if(type in ('payment_refund', 'refund'), amount, 0)) as total_refunds,
      sum(amount) as total_gross_transaction_amount,
      sum(fee) as total_fees,
      sum(net) as total_net_transaction_amount,
      sum(if(type in ('payment', 'charge'), 1, 0)) as total_sales_count,
      sum(if(type in ('payment_refund', 'refund'), 1, 0)) as total_refund_count,    
      sum(if(type in ('charge', 'payment') and date_trunc(date(created_at), month) = date_trunc(current_date(), month),amount, 0)) as sales_this_month,
      sum(if(type in ('payment_refund', 'refund') and date_trunc(date(created_at), month) = date_trunc(current_date(), month), amount, 0)) as refunds_this_month,
      sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), amount, 0)) as gross_transaction_amount_this_month,
      sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), fee, 0)) as fees_this_month,
      sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), net, 0)) as net_transaction_amount_this_month,
      sum(if(type in ('payment', 'charge') and date_trunc(date(created_at), month) = date_trunc(current_date(), month) , 1, 0)) as sales_count_this_month,
      sum(if(type in ('payment_refund', 'refund') and date_trunc(date(created_at), month) = date_trunc(current_date(), month) , 1, 0)) as refund_count_this_month,
      min(if(type in ('payment', 'charge'), date(created_at), null)) as first_sale_date,
      max(if(type in ('payment', 'charge'), date(created_at), null)) as most_recent_sale_date
    from balance_transaction_joined
      where type in ('payment', 'charge', 'payment_refund', 'refund')
    group by 1

), failed_charges_by_customer as (

    select
      customer_id,
      count(*) as total_failed_charge_count,
      sum(amount) as total_failed_charge_amount,
      sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), 1, 0)) as failed_charge_count_this_month,
      sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), amount, 0)) as failed_charge_amount_this_month
    from incomplete_charges
    group by 1

)

select
  coalesce(customer.description, customer.customer_id, 'No associated customer') as customer_description,
  customer.email,
  customer.created_at as customer_created_at,
  customer.is_deliguent,
  coalesce(transactions_grouped.total_sales/100.0, 0) as total_sales,
  coalesce(transactions_grouped.total_refunds/100.0, 0) as total_refunds,
  coalesce(transactions_grouped.total_gross_transaction_amount/100.0, 0) as total_gross_transcation_amount,
  coalesce(transactions_grouped.total_fees/100.0, 0) as total_fees,
  coalesce(transactions_grouped.total_net_transaction_amount/100.0, 0) as total_net_trasnaction_amount,
  coalesce(transactions_grouped.total_sales_count, 0) as total_sales_count,
  coalesce(transactions_grouped.total_refund_count, 0) as total_refund_count,    
  coalesce(transactions_grouped.sales_this_month/100.0, 0) as sales_this_month,
  coalesce(transactions_grouped.refunds_this_month/100.0, 0) as refunds_this_month,
  coalesce(transactions_grouped.gross_transaction_amount_this_month/100.0, 0) as gross_transaction_amount_this_month,
  coalesce(transactions_grouped.fees_this_month/100.0, 0) as fees_this_month,
  coalesce(transactions_grouped.net_transaction_amount_this_month/100.0, 0) as net_transaction_amount_this_month,
  coalesce(transactions_grouped.sales_count_this_month, 0) as sales_count_this_month,
  coalesce(transactions_grouped.refund_count_this_month, 0) as refund_count_this_month,
  transactions_grouped.first_sale_date,
  transactions_grouped.most_recent_sale_date,
  coalesce(total_failed_charge_count, 0) as total_failed_charge_count,
  coalesce(total_failed_charge_amount/100, 0) as total_failed_charge_amount,
  coalesce(failed_charge_count_this_month, 0) as failed_charge_count_this_month,
  coalesce(failed_charge_amount_this_month/100, 0) as failed_charge_amount_this_month,
  customer.currency as customer_currency,
  customer.default_card_id,
  customer.shipping_name,
  customer.shipping_address_line_1,
  customer.shipping_address_line_2,
  customer.shipping_address_city,
  customer.shipping_address_state,
  customer.shipping_address_country,
  customer.shipping_address_postal_code,
  customer.shipping_phone
from customer
left join transactions_grouped on transactions_grouped.customer_id = customer.customer_id
left join failed_charges_by_customer on customer.customer_id = failed_charges_by_customer.customer_id