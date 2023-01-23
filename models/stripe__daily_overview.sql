{% set total_fields =  ['total_daily_sales_amount', 'total_daily_refunds_amount', 'total_daily_adjustments_amount', 'total_daily_other_transactions_amount', 'total_daily_gross_transaction_amount', 'total_daily_net_transactions_amount', 'total_daily_payout_fee_amount', 'total_daily_gross_payout_amount', 'daily_net_activity_amount', 'daily_end_balance_amount', 'total_daily_sales_count', 'total_daily_payouts_count', 'total_daily_adjustments_count', 'total_daily_failed_charge_count', 'total_daily_failed_charge_amount'] %}
{% set rolling_fields = ['rolling_total_daily_sales_amount', 'rolling_total_daily_refunds_amount', 'rolling_total_daily_adjustments_amount', 'rolling_total_daily_other_transactions_amount', 'rolling_total_daily_gross_transaction_amount', 'rolling_total_daily_net_transactions_amount', 'rolling_total_daily_payout_fee_amount', 'rolling_total_daily_gross_payout_amount', 'rolling_daily_net_activity_amount', 'rolling_daily_end_balance_amount', 'rolling_total_daily_sales_count', 'rolling_total_daily_payouts_count', 'rolling_total_daily_adjustments_count', 'rolling_total_daily_failed_charge_count', 'rolling_total_daily_failed_charge_amount'] %}

with date_spine as (

    select * 
    from {{ ref('int_stripe__date_spine') }}

), account_daily_balances_by_type as (

    select * 
    from {{ ref('int_stripe__account_daily')}}

), account_rolling_totals as (

    select
        *

        {% for t in total_fields %}
        , sum({{ t }}) over (order by date_day rows unbounded preceding) as rolling_{{ t }}
        {% endfor %}

    from account_daily_balances_by_type

), final as (

    select
        coalesce(account_rolling_totals.date_day, date_spine.date_day) as date,

        {% for t in total_fields %}
        round(account_rolling_totals.{{ t }},2) as {{ t }},
        {% endfor %}

        {% for f in rolling_fields %}
        case when account_rolling_totals.{{ f }} is null and date_index = 1
            then 0
            else round(account_rolling_totals.{{ f }},2)
            end as {{ f }},
        {% endfor %}

        date_spine.date_index,
        account_rolling_totals.source_relation

    from date_spine
    left join account_rolling_totals
        on account_rolling_totals.date_day = date_spine.date_day
        and account_rolling_totals.source_relation = date_spine.source_relation
)

select * 
from final
