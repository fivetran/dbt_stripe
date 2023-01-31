{% set rolling_fields = ['rolling_total_daily_sales_amount', 'rolling_total_daily_refunds_amount', 'rolling_total_daily_adjustments_amount', 'rolling_total_daily_other_transactions_amount', 'rolling_total_daily_gross_transaction_amount', 'rolling_total_daily_net_transactions_amount', 'rolling_total_daily_payout_fee_amount', 'rolling_total_daily_gross_payout_amount', 'rolling_daily_net_activity_amount', 'rolling_daily_end_balance_amount', 'rolling_total_daily_sales_count', 'rolling_total_daily_payouts_count', 'rolling_total_daily_adjustments_count', 'rolling_total_daily_failed_charge_count', 'rolling_total_daily_failed_charge_amount'] %}

with account_rolling_totals as (

    select * 
    from {{ ref('int_stripe__account_rolling_totals') }}
),


final as (

    select
        *,
        {% for f in rolling_fields %}
        sum(case when {{ f }} is null  
            then 0  
            else 1  
                end) over (order by date_day rows unbounded preceding) as {{ f }}_partition
        {%- if not loop.last -%},{%- endif -%}
        {% endfor %}                  
    from account_rolling_totals
)

select * 
from final