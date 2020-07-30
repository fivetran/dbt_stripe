with  __dbt__CTE__stripe_balance_transaction_joined as (
with balance_transaction as (

    select *
    from `dbt-package-testing`.`dbt_kristin_2`.`stg_stripe_balance_transaction`
  
), charge as (

    select *
    from `dbt-package-testing`.`dbt_kristin_2`.`stg_stripe_charge`

), payment_intent as (

    select *
    from `dbt-package-testing`.`dbt_kristin_2`.`stg_stripe_payment_intent`

), card as (

    select *
    from `dbt-package-testing`.`dbt_kristin_2`.`stg_stripe_card`

), payout as (

    select *
    from `dbt-package-testing`.`dbt_kristin_2`.`stg_stripe_payout`

), refund as (

    select *
    from `dbt-package-testing`.`dbt_kristin_2`.`stg_stripe_refund`

), customer as (

    select *
    from `dbt-package-testing`.`dbt_kristin_2`.`stg_stripe_customer`


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
  
  

        datetime_add(
            cast( balance_transaction.available_on as datetime),
        interval 1 day
        )


 as effective_at,
  coalesce(charge.customer_id, refund_charge.customer_id) as customer_id,
  charge.receipt_email,
  customer.description as customer_description,
  charge.charge_id,
  charge.payment_intent_id,
  charge.created_at as charge_created_at,
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
left join card on charge.card_id = card.card_id
left join payout on payout.balance_transaction_id = balance_transaction.balance_transaction_id
left join refund on refund.balance_transaction_id = balance_transaction.balance_transaction_id
left join charge as refund_charge on refund.charge_id = refund_charge.charge_id
order by created_at desc
),  __dbt__CTE__stripe_incomplete_charges as (
with charge as (

    select *
    from `dbt-package-testing`.`dbt_kristin_2`.`stg_stripe_charge`

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

), daily_balance_transactions as (

  select
    date(case when type = 'payout' 
          then available_on 
          else created_at end) as date,
    sum(case when type in ('charge', 'payment') 
          then amount 
          else 0 end) as total_sales,
    sum(case when type in ('payment_refund', 'refund') 
          then amount 
          else 0 end) as total_refunds,
    sum(case when type = 'adjustment' 
          then amount 
          else 0 end) as total_adjustments,
    sum(case when type not in ('charge', 'payment', 'payment_refund', 'refund', 'adjustment', 'payout') and type not like '%transfer%' 
          then amount 
          else 0 end) as total_other_transactions,
    sum(case when type <> 'payout' and type not like '%transfer%' 
          then amount 
          else 0 end) as total_gross_transaction_amount,
    sum(case when type <> 'payout' and type not like '%transfer%' 
          then net 
          else 0 end) as total_net_tranactions,
    sum(case when type = 'payout' or type like '%transfer%' 
          then fee * -1.0
          else 0 end) as total_payout_fees,
    sum(case when type = 'payout' or type like '%transfer%' 
          then amount 
          else 0 end) as total_gross_payout_amount,
    sum(case when type = 'payout' or type like '%transfer%' 
          then fee * -1.0 
          else net end) as daily_net_activity,
    sum(case when type in ('payment', 'charge') 
          then 1 
          else 0 end) as total_sales_count,
    sum(case when type = 'payout' 
          then 1 
          else 0 end) as total_payouts_count,
    count(distinct case when type = 'adjustment' 
            then coalesce(source, payout_id) 
            else null end) as total_adjustments_count
  from balance_transaction_joined
  group by 1

), daily_failed_charges as (

    select
      date(created_at) as date,
      count(*) as total_failed_charge_count,
      sum(amount) as total_failed_charge_amount
    from incomplete_charges
    group by 1

)

select
  daily_balance_transactions.date,
  daily_balance_transactions.total_sales/100.0 as total_sales,
  daily_balance_transactions.total_refunds/100.0 as total_refunds,
  daily_balance_transactions.total_adjustments/100.0 as total_adjustments,
  daily_balance_transactions.total_other_transactions/100.0 as total_other_transactions,
  daily_balance_transactions.total_gross_transaction_amount/100.0 as total_gross_transaction_amount,
  daily_balance_transactions.total_net_tranactions/100.0 as total_net_tranactions,
  daily_balance_transactions.total_payout_fees/100.0 as total_payout_fees,
  daily_balance_transactions.total_gross_payout_amount/100.0 as total_gross_payout_amount,
  daily_balance_transactions.daily_net_activity/100.0 as daily_net_activity,
  (daily_balance_transactions.daily_net_activity + daily_balance_transactions.total_gross_payout_amount)/100.0 as daily_end_balance,
  daily_balance_transactions.total_sales_count,
  daily_balance_transactions.total_payouts_count,
  daily_balance_transactions.total_adjustments_count,
  coalesce(daily_failed_charges.total_failed_charge_count, 0) as total_failed_charge_count,
  coalesce(daily_failed_charges.total_failed_charge_amount/100, 0) as total_failed_charge_amount
from daily_balance_transactions
left join daily_failed_charges on daily_balance_transactions.date = daily_failed_charges.date
order by 1 desc