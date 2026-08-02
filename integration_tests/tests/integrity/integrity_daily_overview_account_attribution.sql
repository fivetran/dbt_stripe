-- An account cannot report more activity than belongs to it.
--
-- `int_stripe__account_daily` joined the date spine to balance transactions on
-- date and source_relation only, never on the account, so every account on a
-- destination counted every other account's transactions as its own. With N
-- accounts each one's daily sales were the whole platform's.
--
-- The ceiling below is deliberately generous: a transaction whose
-- `connected_account_id` is null cannot be attributed from the source at all
-- (this is every non-Connect destination), so it is allowed to count for any
-- account. What must never happen is an account counting a transaction that
-- names a DIFFERENT account, and that is what this catches.

with charges as (

    select
        cast({{ dbt.date_trunc('day', 'balance_transaction_created_at') }} as date) as date_day,
        source_relation,
        connected_account_id,
        count(*) as charge_count
    from {{ ref('stripe__balance_transactions') }}
    where balance_transaction_type in ('charge', 'payment')
    group by 1, 2, 3

), attributable as (

    select
        overview.account_id,
        overview.source_relation,
        overview.date_day,
        coalesce(sum(charges.charge_count), 0) as most_it_could_be
    from {{ ref('stripe__daily_overview') }} overview
    left join charges
        on charges.date_day = overview.date_day
        and charges.source_relation = overview.source_relation
        and coalesce(charges.connected_account_id, overview.account_id) = overview.account_id
    group by 1, 2, 3
)

select
    overview.account_id,
    overview.date_day,
    overview.total_daily_sales_count,
    attributable.most_it_could_be
from {{ ref('stripe__daily_overview') }} overview
join attributable
    on attributable.account_id = overview.account_id
    and attributable.source_relation = overview.source_relation
    and attributable.date_day = overview.date_day
where overview.total_daily_sales_count > attributable.most_it_could_be
