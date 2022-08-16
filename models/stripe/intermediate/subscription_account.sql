SELECT id, stripe_account

FROM {{source('dbt_stripe_account_src', 'subscription_history')}}
where _fivetran_active = True
order by 1