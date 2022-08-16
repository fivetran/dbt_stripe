SELECT 
  sim.subscription_id,
  sim.customer_id,
  c.name,
  CASE WHEN sim.stripe_account = 'us' then (sum(mrr)/100)
  ELSE sum(mrr)
  END as mrr,
  sim.stripe_account
FROM {{ref('stripe__subscription_items_mrr')}} sim
left join {{source('dbt_stripe_account_src', 'customer')}} c on c.id = sim.customer_id and sim.stripe_account = c.stripe_account
where mrr > 0
group by 1,2,3,5