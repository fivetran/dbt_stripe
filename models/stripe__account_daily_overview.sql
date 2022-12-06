with 

account as (

    select *
    from {{ var('account') }}  

),

account_rolling_totals as (

    select *
    from 

), balance_transaction_joined as (

    select *
    from {{ ref('stripe__balance_transactions') }}  

),

select
    account.account_id,
    account_rolling_totals.date_day,
    {{ dbt_utils.surrogate_key(['account.account_id','account_rolling_totals.date_day']) }} as account_daily_id,
    reporting_category,
    sum(amount)


    group by 1, 2, 3, 4
    
    from account
    left join account_rolling_totals
        on account
    left join balance_transaction_joined 
        on account.account_id = balance_transaction_id.connected_account_id

