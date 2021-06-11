with balance_transaction_joined as (

    select *
    from {{ ref('stripe__balance_transactions') }}  

), incomplete_charges as (

    select *
    from {{ ref('int_stripe__incomplete_charges') }}  

), daily_balance_transactions as (

  select
      case 
            when type = 'payout' 
            then {{ date_timezone('available_on') }}  
            else {{ date_timezone('created_at') }} 
      end as date,
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
          else 0 end) as total_net_transactions,
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
      {{ date_timezone('created_at') }} as date,
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
      daily_balance_transactions.total_net_transactions/100.0 as total_net_transactions,
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

left join daily_failed_charges 
      on daily_balance_transactions.date = daily_failed_charges.date
