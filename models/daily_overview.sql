with balance_transactions_joined as (

    select *
    from {{ ref('stripe_balance_transaction_joined') }}  

), daily_balance_transactions as (

  select
    date(case when type = 'payout' then available_on else created end) as date, -- payouts are considered when they are posted (available_on)
    currency,
    sum(case when type in ('charge', 'payment') then amount else 0 end) as sales,
    sum(case when type in ('payment_refund', 'refund') then amount else 0 end) as refunds,
    sum(case when type = 'adjustment' then amount else 0 end) as adjustments,
    sum(case when type not in ('charge', 'payment', 'payment_refund', 'refund', 'adjustment', 'payout') and type not like '%transfer%' then amount else 0 end) as other,
    sum(case when type <> 'payout' and type not like '%transfer%' then amount else 0 end) as gross_transactions,
    sum(case when type <> 'payout' and type not like '%transfer%' then net else 0 end) as net_transactions,
    sum(case when type = 'payout' or type like '%transfer%' then fee * -1.0 else 0 end) as payout_fees,
    sum(case when type = 'payout' or type like '%transfer%' then amount else 0 end) as gross_payouts,
    sum(case when type = 'payout' or type like '%transfer%' then fee * -1.0 else net end) as daily_net_activity,
    sum(if(type in ('payment', 'charge'), 1, 0)) as sales_count,
    sum(if(type = 'payout', 1, 0)) as payouts_count,
    count(distinct case when type = 'adjustment' then source end) as adjustments_count
  from balance_transaction_joined
  group by 1, 2

)

select
  date,
  currency,
  sales/100.0 as sales,
  refunds/100.0 as refunds,
  adjustments/100.0 as adjustments,
  other/100.0 as other,
  gross_transactions/100.0 as gross_transactions,
  net_transactions/100.0 as net_transactions,
  payout_fees/100.0 as payout_fees,
  gross_payouts/100.0 as gross_payouts,
  daily_net_activity/100.0 as daily_net_activity,
  sum(daily_net_activity + gross_payouts) over(partition by currency order by date)/100.0 as daily_end_balance, -- use SUM Window Function
  sales_count,
  payouts_count,
  adjustments_count
from daily_balance_transactions
where date < current_date() -- exclude current, partial day
order by 1 desc, 2



