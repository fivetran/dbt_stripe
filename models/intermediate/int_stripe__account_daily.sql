{{ config(enabled=var('customer360__using_stripe', true)) }}

with date_spine as (

    select * 
    from {{ ref('int_stripe__date_spine') }}

), balance_transaction as (

    select *,
        case 
            when balance_transaction_type = 'payout' 
            then {{ date_timezone('balance_transaction_available_on') }}  
            else {{ date_timezone('balance_transaction_created_at') }}
        end as date
    from {{ ref('stripe__balance_transactions') }}

), incomplete_charges as (

    select *
    from {{ ref('int_stripe__incomplete_charges') }}  

), daily_account_balance_transactions as (

    select
        date_spine.date_day,
        date_spine.account_id,
        date_spine.source_relation,
        sum(case when balance_transaction.balance_transaction_type in ('charge', 'payment') 
            then balance_transaction.balance_transaction_amount
            else 0 end) as total_daily_sales_amount,
        sum(case when balance_transaction.balance_transaction_type in ('payment_refund', 'refund') 
            then balance_transaction.balance_transaction_amount
            else 0 end) as total_daily_refunds_amount,
        sum(case when balance_transaction.balance_transaction_type = 'adjustment' 
            then balance_transaction.balance_transaction_amount
            else 0 end) as total_daily_adjustments_amount,
        sum(case when balance_transaction.balance_transaction_type not in ('charge', 'payment', 'payment_refund', 'refund', 'adjustment', 'payout') and balance_transaction.balance_transaction_type not like '%transfer%' 
            then balance_transaction.balance_transaction_amount
            else 0 end) as total_daily_other_transactions_amount,
        sum(case when balance_transaction.balance_transaction_type <> 'payout' and balance_transaction.balance_transaction_type not like '%transfer%' 
            then balance_transaction.balance_transaction_amount
            else 0 end) as total_daily_gross_transaction_amount,
        sum(case when balance_transaction.balance_transaction_type <> 'payout' and balance_transaction.balance_transaction_type not like '%transfer%' 
            then balance_transaction_net 
            else 0 end) as total_daily_net_transactions_amount,
        sum(case when balance_transaction.balance_transaction_type = 'payout' or balance_transaction.balance_transaction_type like '%transfer%' 
            then balance_transaction_fee * -1.0
            else 0 end) as total_daily_payout_fee_amount,
        sum(case when balance_transaction.balance_transaction_type = 'payout' or balance_transaction.balance_transaction_type like '%transfer%' 
            then balance_transaction.balance_transaction_amount
            else 0 end) as total_daily_gross_payout_amount,
        sum(case when balance_transaction.balance_transaction_type = 'payout' or balance_transaction.balance_transaction_type like '%transfer%' 
            then balance_transaction_fee * -1.0 
            else balance_transaction_net end) as daily_net_activity_amount,
        sum(case when balance_transaction.balance_transaction_type in ('payment', 'charge') 
            then 1 
            else 0 end) as total_daily_sales_count,
        sum(case when balance_transaction.balance_transaction_type = 'payout' 
            then 1
            else 0 end) as total_daily_payouts_count,
        count(distinct case when balance_transaction.balance_transaction_type = 'adjustment' 
                then coalesce(balance_transaction_source_id, payout_id) 
                else null end) as total_daily_adjustments_count
    from date_spine
    left join balance_transaction
        on cast({{ dbt.date_trunc('day', 'balance_transaction.date') }} as date) = date_spine.date_day
        and balance_transaction.source_relation = date_spine.source_relation
    group by 1,2,3

), daily_failed_charges as (

    select
        {{ date_timezone('created_at') }} as date,
        source_relation,
        count(*) as total_daily_failed_charge_count,
        sum(amount) as total_daily_failed_charge_amount
    from incomplete_charges
    group by 1,2
)

select
    daily_account_balance_transactions.date_day,
    daily_account_balance_transactions.account_id,
    daily_account_balance_transactions.source_relation,
    coalesce(daily_account_balance_transactions.total_daily_sales_amount/100.0,0) as total_daily_sales_amount,
    coalesce(daily_account_balance_transactions.total_daily_refunds_amount/100.0,0) as total_daily_refunds_amount,
    coalesce(daily_account_balance_transactions.total_daily_adjustments_amount/100.0,0) as total_daily_adjustments_amount,
    coalesce(daily_account_balance_transactions.total_daily_other_transactions_amount/100.0,0) as total_daily_other_transactions_amount,
    coalesce(daily_account_balance_transactions.total_daily_gross_transaction_amount/100.0,0) as total_daily_gross_transaction_amount,
    coalesce(daily_account_balance_transactions.total_daily_net_transactions_amount/100.0,0) as total_daily_net_transactions_amount,
    coalesce(daily_account_balance_transactions.total_daily_payout_fee_amount/100.0,0) as total_daily_payout_fee_amount,
    coalesce(daily_account_balance_transactions.total_daily_gross_payout_amount/100.0,0) as total_daily_gross_payout_amount,
    coalesce(daily_account_balance_transactions.daily_net_activity_amount/100.0,0) as daily_net_activity_amount,
    coalesce((daily_account_balance_transactions.daily_net_activity_amount + daily_account_balance_transactions.total_daily_gross_payout_amount)/100.0, 0) as daily_end_balance_amount,
    coalesce(daily_account_balance_transactions.total_daily_sales_count, 0) as total_daily_sales_count,
    coalesce(daily_account_balance_transactions.total_daily_payouts_count, 0) as total_daily_payouts_count,
    coalesce(daily_account_balance_transactions.total_daily_adjustments_count, 0) as total_daily_adjustments_count,
    coalesce(daily_failed_charges.total_daily_failed_charge_count, 0) as total_daily_failed_charge_count,
    coalesce(daily_failed_charges.total_daily_failed_charge_amount/100, 0) as total_daily_failed_charge_amount

from daily_account_balance_transactions
left join daily_failed_charges
    on daily_account_balance_transactions.date_day = daily_failed_charges.date
    and daily_account_balance_transactions.source_relation = daily_failed_charges.source_relation
