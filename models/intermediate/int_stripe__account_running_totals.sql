{% set rolling_fields = ['rolling_total_daily_sales_amount', 'rolling_total_daily_refunds_amount', 'rolling_total_daily_adjustments_amount', 'rolling_total_daily_other_transactions_amount', 'rolling_total_daily_gross_transaction_amount', 'rolling_total_daily_net_transactions_amount', 'rolling_total_daily_payout_fee_amount', 'rolling_total_daily_gross_payout_amount', 'rolling_daily_net_activity_amount', 'rolling_daily_end_balance_amount', 'rolling_total_daily_sales_count', 'rolling_total_daily_payouts_count', 'rolling_total_daily_adjustments_count', 'rolling_total_daily_failed_charge_count', 'rolling_total_daily_failed_charge_amount'] %}


with account_partitions as (

    select * 
    from {{ ref('int_stripe__account_partitions') }}
),

final as (

    select
        account_id,
        {{ dbt_utils.generate_surrogate_key(['account_id','date_day']) }} as account_daily_id,

        date_day,        
        date_week,
        date_month, 
        date_year,  
        date_index,
        source_relation,
        coalesce(total_daily_sales_amount,0) as total_daily_sales_amount,
        coalesce(total_daily_refunds_amount,0) as total_daily_refunds_amount,
        coalesce(total_daily_adjustments_amount,0) as total_daily_adjustments_amount,
        coalesce(total_daily_other_transactions_amount,0) as total_daily_other_transactions_amount,
        coalesce(total_daily_gross_transaction_amount,0) as total_daily_gross_transaction_amount,
        coalesce(total_daily_net_transactions_amount,0) as total_daily_net_transactions_amount,
        coalesce(total_daily_payout_fee_amount,0) as total_daily_payout_fee_amount,
        coalesce(total_daily_gross_payout_amount,0) as total_daily_gross_payout_amount,
        coalesce(daily_net_activity_amount,0) as daily_net_activity_amount,
        coalesce(daily_end_balance_amount,0) as daily_end_balance_amount,
        coalesce(total_daily_sales_count,0) as total_daily_sales_count,
        coalesce(total_daily_payouts_count,0) as total_daily_payouts_count,
        coalesce(total_daily_adjustments_count,0) as total_daily_adjustments_count,
        coalesce(total_daily_failed_charge_count,0) as total_daily_failed_charge_count,
        coalesce(total_daily_failed_charge_amount,0) as total_daily_failed_charge_amount,
        {% for f in rolling_fields %}
        coalesce({{ f }},   
            first_value({{ f }}) over (partition by {{ f }}_partition order by date_day rows unbounded preceding)) as {{ f }}
        {%- if not loop.last -%},{%- endif -%}
        {% endfor %}

    from account_partitions
)    

select *
from final