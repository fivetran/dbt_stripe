with balance_transaction as (

    select *
    from {{ ref('stripe__balance_transactions') }}
),

final as (

    select
        account_id,
        type,
        reporting_category,
        cast( {{dbt.date_trunc("day", "created_at") }} as date) as date_day,
        count(distinct balance_transaction_id) as daily_transaction_count,
        sum(amount) as daily_amount,
        sum(fee) as daily_fee_amount,
        sum(net) as dailt_net_amount,
    from balance_transaction
    {{ dbt_utils.group_by(4) }}

)

select * 
from final