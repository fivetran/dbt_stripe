with daily_overview as (

    select *
    from {{ ref('stripe__daily_overview') }}  

)

select
    {{ dbt_utils.date_trunc('month', 'date')}} as month,
    sum(total_sales) as total_sales,
    sum(total_refunds) as total_refunds,
    sum(total_adjustments) as total_adjustments,
    sum(total_other_transactions) as total_other_transactions,
    sum(total_gross_transaction_amount) as total_gross_transaction_amount,
    sum(total_net_transactions) as total_net_transactions,
    sum(total_payout_fees) as total_payout_fees,
    sum(total_gross_payout_amount) as total_gross_payout_amount,
    sum(daily_net_activity) as monthly_net_activity,
    sum(total_sales_count) as total_sales_count,
    sum(total_payouts_count) as total_payouts_count,
    sum(total_adjustments_count) as total_adjustments_count,
    sum(total_failed_charge_count) as total_failed_charge_count,
    sum(total_failed_charge_amount) as total_failed_charge_amount,
    sum( total_sales_b2b) as total_sales_b2b,
    sum(total_refunds_b2b) as total_refunds_b2b,
    sum(total_adjustments_b2b) as total_adjustments_b2b,
    sum(total_sales_b2c) as total_sales_b2c,
    sum(total_refunds_b2c) as total_refunds_b2c,
    sum(total_adjustments_b2c) as total_adjustments_b2c,
    sum(total_sales_unattributed) as total_sales_unattributed,
    sum(total_refunds_unattributed) as total_refunds_unattributed,
    sum(total_adjustments_unattributed) as total_adjustments_unattributed
from daily_overview
group by 1
