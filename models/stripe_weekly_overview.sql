with balance_transaction_joined as (

    select *
    from {{ ref('stripe_balance_transaction_joined') }}  

), incomplete_charges as (

    select *
    from {{ ref('stripe_incomplete_charges') }}  

), weekly_balance_transactions as (

  select
    date_trunc(date(case when type = 'payout' then available_on else created_at end), week) as week,
    sum(case when type in ('charge', 'payment') then amount else 0 end) as total_sales,
    sum(case when type in ('payment_refund', 'refund') then amount else 0 end) as total_refunds,
    sum(case when type = 'adjustment' then amount else 0 end) as total_adjustments,
    sum(case when type not in ('charge', 'payment', 'payment_refund', 'refund', 'adjustment', 'payout') and type not like '%transfer%' then amount else 0 end) as total_other_transactions,
    sum(case when type <> 'payout' and type not like '%transfer%' then amount else 0 end) as total_gross_transaction_amount,
    sum(case when type <> 'payout' and type not like '%transfer%' then net else 0 end) as total_net_tranactions,
    sum(case when type = 'payout' or type like '%transfer%' then fee * -1.0 else 0 end) as total_payout_fees,
    sum(case when type = 'payout' or type like '%transfer%' then amount else 0 end) as total_gross_payout_amount,
    sum(case when type = 'payout' or type like '%transfer%' then fee * -1.0 else net end) as weekly_net_activity,
    sum(if(type in ('payment', 'charge'), 1, 0)) as total_sales_count,
    sum(if(type = 'payout', 1, 0)) as payouts_count,
    count(distinct case when type = 'adjustment' then coalesce(source, payout_id) end) as total_adjustments_count
  from balance_transaction_joined
  group by 1

), weekly_failed_charges as (

    select
      date_trunc(date(created_at), week) as week,
      count(*) as total_failed_charge_count,
      sum(amount) as total_failed_charge_amount
    from incomplete_charges
    group by 1

)

select
  weekly_balance_transactions.week,
  weekly_balance_transactions.total_sales/100.0 as total_sales,
  weekly_balance_transactions.total_refunds/100.0 as total_refunds,
  weekly_balance_transactions.total_adjustments/100.0 as total_adjustments,
  weekly_balance_transactions.total_other_transactions/100.0 as total_other_transactions,
  weekly_balance_transactions.total_gross_transaction_amount/100.0 as total_gross_transaction_amount,
  weekly_balance_transactions.total_net_tranactions/100.0 as total_net_tranactions,
  weekly_balance_transactions.total_payout_fees/100.0 as total_payout_fees,
  weekly_balance_transactions.total_gross_payout_amount/100.0 as total_gross_payout_amount,
  weekly_balance_transactions.weekly_net_activity/100.0 as weekly_net_activity,
  (weekly_balance_transactions.weekly_net_activity + weekly_balance_transactions.total_gross_payout_amount)/100.0 as weekly_end_balance,
  weekly_balance_transactions.total_sales_count,
  weekly_balance_transactions.payouts_count,
  weekly_balance_transactions.total_adjustments_count,
  coalesce(weekly_failed_charges.total_failed_charge_count, 0) as total_failed_charge_count,
  coalesce(weekly_failed_charges.total_failed_charge_amount/100, 0) as total_failed_charge_amount
from weekly_balance_transactions
left join weekly_failed_charges on weekly_balance_transactions.week = weekly_failed_charges.week
order by 1 desc
