with daily_overview as (

    select *
    from {{ ref('stripe__daily_overview') }}  

)

select
    {{ dbt.date_trunc('quarter', 'date')}} as quarter,
    source_relation,
    sum(total_daily_sales_amount) as total_daily_sales_amount,
    sum(total_daily_refunds_amount) as total_daily_refunds_amount,
    sum(total_daily_adjustments_amount) as total_daily_adjustments_amount,
    sum(total_daily_other_transactions_amount) as total_daily_other_transactions_amount,
    sum(total_daily_gross_transaction_amount) as total_daily_gross_transaction_amount,
    sum(total_daily_net_transactions_amount) as total_daily_net_transactions_amount,
    sum(total_daily_payout_fee_amount) as total_daily_payout_fee_amount,
    sum(total_daily_gross_payout_amount) as total_daily_gross_payout_amount,
    sum(daily_net_activity_amount) as daily_net_activity_amount,
    sum(total_daily_sales_count) as total_daily_sales_count,
    sum(total_daily_payouts_count) as total_daily_payouts_count,
    sum(total_daily_adjustments_count) as total_daily_adjustments_count,
    sum(total_daily_failed_charge_count) as total_daily_failed_charge_count,
    sum(total_daily_failed_charge_amount) as total_daily_failed_charge_amount
from daily_overview
group by 1,2
