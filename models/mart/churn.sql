select 
    date_trunc('month', mrr_month )::date as churn_month, 
    customer_id,
    name,
    stripe_account 
from {{ref('mrr_movements_monthly')}} mmm 
where event_type = 'Churn'
    -- Removing test accounts
    and customer_id NOT IN ('cus_MVjwgFklliUF9p','cus_J8IS1IGMxzZLzR')
order by 1 desc