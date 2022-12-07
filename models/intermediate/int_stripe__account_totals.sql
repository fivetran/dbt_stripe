{% set fields = ['rolling_daily_amount','rolling_daily_charge_amount','rolling_daily_refund_amount','rolling_daily_payout_reversal_amount','rolling_daily_transfer_count','rolling_daily_transfer_reversal_amount','rolling_daily_other_amount']

with date_spine as (

    select * 
    from {{ ref('int_stripe__date_spine') }}
),

account_balances as (

    select *
    from {{ ref('int_stripe__account_daily') }}
), 

account_daily_totals_by_category as (

    select 
        account_id,
        date_day,
        sum(amount) as daily_amount,
        sum(case when lower(reporting_category) = 'charge' 
            then amount
            else 0 
            end) as daily_charge_amount,
        sum(case when lower(reporting_category) = 'refund' 
            then amount
            else 0 
            end) as daily_refund_amount,
        sum(case when lower(reporting_category) = 'payout_reversal' 
            then amount
            else 0 
            end) as daily_payout_reversal_amount,
        sum(case when lower(reporting_category) = 'transfer' 
            then amount
            else 0 
            end) as daily_transfer_count,
        sum(case when lower(reporting_category) = 'transfer_reversal' 
            then amount
            else 0 
            end) as daily_transfer_reversal_amount
        sum(case when lower(reporting_category) not in ('charge','refund','payout_reversal','transfer','transfer_reversal')
            then amount
            else 0
            end) as daily_other_amount
    from transactions_grouped
    group by 1, 2
),

account_rolling_totals as (

    select
        *,
        sum(daily_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_daily_amount,
        sum(daily_charge_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_daily_charge_amount,
        sum(daily_refund_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_daily_refund_amount,
        sum(daily_payout_reversal_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_daily_payout_reversal_amount,
        sum(daily_transfer_count) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_daily_transfer_count,
        sum(daily_transfer_reversal_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_daily_transfer_reversal_amount,
        sum(daily_other_amount) over (partition by account_id order by account_id, date_day rows unbounded preceding) as rolling_daily_other_amount
    from account_daily_totals_by_category
),

final as (

    select
        coalesce(account_rolling_totals.account_id, balance_transaction_periods.account_id) as account_id,
        coalesce(account_rolling_totals.date_day, balance_transaction_periods.date_day) as date_day,
        account_rolling_totals.daily_amount,
        account_rolling_totals.daily_charge_amount,
        account_rolling_totals.daily_refund_amount,
        account_rolling_totals.daily_payout_reversal_amount,
        account_rolling_totals.daily_transfer_count,
        account_rolling_totals.daily_transfer_reversal_amount,
        account_rolling_totals.daily_other_amount,

        {% for f in fields %}
        case when account_rolling_totals.{{ f }} is null and date_index = 1
            then 0
            else account_rolling_totals.{{ f }}
            end as {{ f }},
        {% endfor %}

        balance_transaction_periods.date_index
    from balance_transaction_periods

    left join account_rolling_totals
        on account_rolling_totals.account_id = balance_transaction_periods.account_id 
        and account_rolling_totals.date_day = balance_transaction_periods.date_day
        and account_rolling_totals.date_week = balance_transaction_periods.date_week
        and account_rolling_totals.date_month = balance_transaction_periods.date_month
        and account_rolling_totals.date_year = balance_transaction_periods.date_year
)

select * 
from final
