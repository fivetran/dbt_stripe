{% set total_fields = ['total_daily_sales_amount', 'total_daily_refunds_amount', 'total_daily_adjustments_amount', 'total_daily_other_transactions_amount', 'total_daily_gross_transaction_amount', 'total_daily_net_transactions_amount', 'total_daily_payout_fee_amount', 'total_daily_gross_payout_amount', 'daily_net_activity_amount', 'daily_end_balance_amount', 'total_daily_sales_count', 'total_daily_payouts_count', 'total_daily_adjustments_count', 'total_daily_failed_charge_count', 'total_daily_failed_charge_amount'] %}

-- Every rolling_* column must be the running total of its own account's daily
-- values, and nobody else's. Before this test existed the rolling windows had
-- no `partition by`, so an account's running total silently accumulated every
-- other account's activity too: with two accounts each one's final rolling
-- sales came out at exactly 2x its own sales.
--
-- Deliberately not gated behind `fivetran_validation_tests_enabled`. The bug
-- this guards shipped for a long time precisely because nothing checked it on
-- an ordinary run, and the check costs one query.

with daily_overview as (

    select *
    from {{ ref('stripe__daily_overview') }}
),

expected as (

    select
        account_id,
        source_relation,
        date_day

        {% for t in total_fields %}
        , rolling_{{ t }}
        , sum({{ t }}) over (
            partition by account_id, source_relation
            order by date_day
            rows unbounded preceding) as expected_rolling_{{ t }}
        {% endfor %}

    from daily_overview
)

select *
from expected
where
    {% for t in total_fields %}
    abs(rolling_{{ t }} - expected_rolling_{{ t }}) > 0.01
    {%- if not loop.last %} or {% endif %}
    {% endfor %}
