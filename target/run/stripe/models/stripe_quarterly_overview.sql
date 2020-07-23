

  create or replace table `dbt-package-testing`.`dbt_kristin_2`.`stripe_quarterly_overview`
  
  
  OPTIONS()
  as (
    with balance_transaction_joined as (

    select *
    from `dbt-package-testing`.`dbt_kristin_2`.`stripe_balance_transaction_joined`  

), incomplete_charges as (

    select *
    from `dbt-package-testing`.`dbt_kristin_2`.`stripe_incomplete_charges`  

), quarterly_balance_transactions as (

  select
    date_trunc(date(case when type = 'payout' then available_on else created_at end), quarter) as quarter,
    sum(case when type in ('charge', 'payment') then amount else 0 end) as total_sales,
    sum(case when type in ('payment_refund', 'refund') then amount else 0 end) as total_refunds,
    sum(case when type = 'adjustment' then amount else 0 end) as total_adjustments,
    sum(case when type not in ('charge', 'payment', 'payment_refund', 'refund', 'adjustment', 'payout') and type not like '%transfer%' then amount else 0 end) as total_other_transactions,
    sum(case when type <> 'payout' and type not like '%transfer%' then amount else 0 end) as total_gross_transaction_amount,
    sum(case when type <> 'payout' and type not like '%transfer%' then net else 0 end) as total_net_tranactions,
    sum(case when type = 'payout' or type like '%transfer%' then fee * -1.0 else 0 end) as total_payout_fees,
    sum(case when type = 'payout' or type like '%transfer%' then amount else 0 end) as total_gross_payout_amount,
    sum(case when type = 'payout' or type like '%transfer%' then fee * -1.0 else net end) as quarterly_net_activity,
    sum(if(type in ('payment', 'charge'), 1, 0)) as total_sales_count,
    sum(if(type = 'payout', 1, 0)) as total_payout_count,
    count(distinct case when type = 'adjustment' then coalesce(source, payout_id) end) as total_adjustments_count
  from balance_transaction_joined
  group by 1

), quarterly_failed_charges as (

    select
      date_trunc(date(created_at), quarter) as quarter,
      count(*) as total_failed_charge_count,
      sum(amount) as total_failed_charge_amount
    from incomplete_charges
    group by 1

)

select
  quarterly_balance_transactions.quarter,
  quarterly_balance_transactions.total_sales/100.0 as total_sales,
  quarterly_balance_transactions.total_refunds/100.0 as total_refunds,
  quarterly_balance_transactions.total_adjustments/100.0 as total_adjustments,
  quarterly_balance_transactions.total_other_transactions/100.0 as total_other_transactions,
  quarterly_balance_transactions.total_gross_transaction_amount/100.0 as total_gross_transaction_amount,
  quarterly_balance_transactions.total_net_tranactions/100.0 as total_net_tranactions,
  quarterly_balance_transactions.total_payout_fees/100.0 as total_payout_fees,
  quarterly_balance_transactions.total_gross_payout_amount/100.0 as total_gross_payout_amount,
  quarterly_balance_transactions.quarterly_net_activity/100.0 as quarterly_net_activity,
  (quarterly_balance_transactions.quarterly_net_activity + quarterly_balance_transactions.total_gross_payout_amount)/100.0 as quarterly_end_balance,
  quarterly_balance_transactions.total_sales_count,
  quarterly_balance_transactions.total_payout_count,
  quarterly_balance_transactions.total_adjustments_count,
  coalesce(quarterly_failed_charges.total_failed_charge_count, 0) as total_failed_charge_count,
  coalesce(quarterly_failed_charges.total_failed_charge_amount/100, 0) as total_failed_charge_amount
from quarterly_balance_transactions
left join quarterly_failed_charges on quarterly_balance_transactions.quarter = quarterly_failed_charges.quarter
order by 1 desc
  );
    