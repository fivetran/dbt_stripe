with date_spine as (

    select * 
    from {{ ref('int_stripe__date_spine') }}

), balance_transaction as (

    select *,
        case 
            when type = 'payout' 
            then {{ date_timezone('available_on') }}  
            else {{ date_timezone('created_at') }} 
        end as date
    from {{ ref('stripe__balance_transactions') }}

), incomplete_charges as (

    select *
    from {{ ref('int_stripe__incomplete_charges') }}  

), daily_account_balance_transactions as (

    select
        date_spine.date_day,
        balance_transaction.account_id,
        sum(case when balance_transaction.type in ('charge', 'payment') 
            then balance_transaction.amount
            else 0 end) as total_daily_sales_amount,
        sum(case when balance_transaction.type in ('payment_refund', 'refund') 
            then balance_transaction.amount
            else 0 end) as total_daily_refunds_amount,
        sum(case when balance_transaction.type = 'adjustment' 
            then balance_transaction.amount
            else 0 end) as total_daily_adjustments_amount,
        sum(case when balance_transaction.type not in ('charge', 'payment', 'payment_refund', 'refund', 'adjustment', 'payout') and balance_transaction.type not like '%transfer%' 
            then balance_transaction.amount
            else 0 end) as total_daily_other_transactions_amount,
        sum(case when balance_transaction.type <> 'payout' and balance_transaction.type not like '%transfer%' 
            then balance_transaction.amount
            else 0 end) as total_daily_gross_transaction_amount,
        sum(case when balance_transaction.type <> 'payout' and balance_transaction.type not like '%transfer%' 
            then net 
            else 0 end) as total_daily_net_transactions_amount,
        sum(case when balance_transaction.type = 'payout' or balance_transaction.type like '%transfer%' 
            then fee * -1.0
            else 0 end) as total_daily_payout_fee_amount,
        sum(case when balance_transaction.type = 'payout' or balance_transaction.type like '%transfer%' 
            then balance_transaction.amount
            else 0 end) as total_daily_gross_payout_amount,
        sum(case when balance_transaction.type = 'payout' or balance_transaction.type like '%transfer%' 
            then fee * -1.0 
            else net end) as daily_net_activity_amount,
        sum(case when balance_transaction.type in ('payment', 'charge') 
            then 1 
            else 0 end) as total_daily_sales_count,
        sum(case when balance_transaction.type = 'payout' 
            then 1
            else 0 end) as total_daily_payouts_count,
        count(distinct case when balance_transaction.type = 'adjustment' 
                then coalesce(source, payout_id) 
                else null end) as total_daily_adjustments_count
    from balance_transaction
    left join date_spine 
        on balance_transaction.account_id = date_spine.account_id
        and balance_transaction.date = date_spine.date_day
    group by 1, 2

), daily_failed_charges as (

    select
        {{ date_timezone('created_at') }} as date,
        connected_account_id,
        count(*) as total_daily_failed_charge_count,
        sum(amount) as total_daily_failed_charge_amount
    from incomplete_charges
    group by 1, 2
)

select
    daily_account_balance_transactions.date_day,
    daily_account_balance_transactions.total_daily_sales_amount/100.0 as total_daily_sales_amount,
    daily_account_balance_transactions.total_daily_refunds_amount/100.0 as total_daily_refunds_amount,
    daily_account_balance_transactions.total_daily_adjustments_amount/100.0 as total_daily_adjustments_amount,
    daily_account_balance_transactions.total_daily_other_transactions_amount/100.0 as total_daily_other_transactions_amount,
    daily_account_balance_transactions.total_daily_gross_transaction_amount/100.0 as total_daily_gross_transaction_amount,
    daily_account_balance_transactions.total_daily_net_transactions_amount/100.0 as total_daily_net_transactions_amount,
    daily_account_balance_transactions.total_daily_payout_fee_amount/100.0 as total_daily_payout_fee_amount,
    daily_account_balance_transactions.total_daily_gross_payout_amount/100.0 as total_daily_gross_payout_amount,
    daily_account_balance_transactions.daily_net_activity_amount/100.0 as daily_net_activity_amount,
    (daily_account_balance_transactions.daily_net_activity_amount + daily_account_balance_transactions.total_daily_gross_payout_amount)/100.0 as daily_end_balance_amount,
    daily_account_balance_transactions.total_daily_sales_count,
    daily_account_balance_transactions.total_daily_payouts_count,
    daily_account_balance_transactions.total_daily_adjustments_count,
    coalesce(daily_failed_charges.total_daily_failed_charge_count, 0) as total_daily_failed_charge_count,
    coalesce(daily_failed_charges.total_daily_failed_charge_amount/100, 0) as total_daily_failed_charge_amount
from daily_account_balance_transactions
left join daily_failed_charges 
    on daily_account_balance_transactions.date_day = daily_failed_charges.date
    and daily_account_balance_transactions.account_id = daily_failed_charges.connected_account_id




-- final as (

--     select
--         account_id,
--         balance_transaction.type,
--         reporting_category,
--         cast( {{dbt.date_trunc("day", "created_at") }} as date) as date_day,
--         count(distinct balance_transaction_id) as daily_transaction_count,
--         sum(amount) as daily_amount,
--         sum(fee) as daily_fee_amount,
--         sum(net) as dailt_net_amount,
--     from balance_transaction
--     {{ dbt_utils.group_by(4) }}

-- )

-- select * 
-- from final