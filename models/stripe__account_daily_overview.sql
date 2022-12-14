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
        , sum({{ t }}) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_{{ t }}
        {% endfor %}

        -- , source_relation # add this in upon union_feature merge

        -- sum(total_daily_sales_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_sales_amount,
        -- sum(total_daily_refunds_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_refunds_amount,
        -- sum(total_daily_adjustments_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_adjustments_amount,
        -- sum(total_daily_other_transactions_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_other_transactions_amount,
        -- sum(total_daily_gross_transaction_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_gross_transaction_amount,
        -- sum(total_daily_net_transactions_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_net_transactions_amount,
        -- sum(total_daily_payout_fee_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_payout_fee_amount,
        -- sum(total_daily_gross_payout_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_gross_payout_amount,
        -- sum(daily_net_activity_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_daily_net_activity_amount,
        -- sum(daily_end_balance_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_daily_end_balance_amount,
        -- sum(total_daily_sales_count) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_sales_count,
        -- sum(total_daily_payouts_count) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_payouts_count,
        -- sum(total_daily_adjustments_count) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_adjustments_count,
        -- sum(total_daily_failed_charge_count) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_failed_charge_count,
        -- sum(total_daily_failed_charge_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_total_daily_failed_charge_amount

    from account_daily_balances_by_type

), final as (

    select
        coalesce(account_rolling_totals.account_id, date_spine.account_id) as account_id,
        coalesce(account_rolling_totals.date_day, date_spine.date_day) as date_day,
        -- account_rolling_totals.total_daily_sales_amount,
        -- account_rolling_totals.total_daily_refunds_amount,
        -- account_rolling_totals.total_daily_adjustments_amount,
        -- account_rolling_totals.total_daily_other_transactions_amount,
        -- account_rolling_totals.total_daily_gross_transaction_amount,
        -- account_rolling_totals.total_daily_net_transactions_amount,
        -- account_rolling_totals.total_daily_payout_fee_amount,
        -- account_rolling_totals.total_daily_gross_payout_amount,
        -- account_rolling_totals.daily_net_activity_amount,
        -- account_rolling_totals.daily_end_balance_amount,
        -- account_rolling_totals.total_daily_sales_count,
        -- account_rolling_totals.total_daily_payouts_count,
        -- account_rolling_totals.total_daily_adjustments_count,
        -- account_rolling_totals.total_daily_failed_charge_count,
        -- account_rolling_totals.total_daily_failed_charge_amount,

        {% for t in total_fields %}
        account_rolling_totals.{{ t }},
        {% endfor %}

        {% for f in rolling_fields %}
        case when account_rolling_totals.{{ f }} is null and date_index = 1
            then 0
            else account_rolling_totals.{{ f }}
            end as {{ f }},
        {% endfor %}

        date_spine.date_index
        -- ,
        -- source_relation # add later!

    from date_spine
    left join account_rolling_totals
        on account_rolling_totals.account_id = date_spine.account_id 
        and account_rolling_totals.date_day = date_spine.date_day
)

select * 
from final
