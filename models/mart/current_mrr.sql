SELECT 
  sim.subscription_id,
  sim.customer_id,
  c.name,
  sum(mrr) as mrr,
  pc.name as product_class,
  sim.stripe_account
FROM {{ref('stripe__subscription_items_mrr')}} sim
  left join {{source('dbt_stripe_account_src', 'customer')}} c on c.id = sim.customer_id and sim.stripe_account = c.stripe_account
  left join {{source('dbt_stripe_account_src', 'product')}} p on sim.product_id = p.id 
  left join {{source('dbt_stripe_account_src', 'product_classes')}} pc on pc.id = p.product_class
where mrr > 0
group by 1,2,3,5,6
order by 2 asc