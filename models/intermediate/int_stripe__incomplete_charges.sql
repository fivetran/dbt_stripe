{{ config(enabled=var('customer360__using_stripe', true)) }}

with charge as (

    select *
    from {{ var('charge')}}

)

select 
  balance_transaction_id,
  created_at,
  customer_id,
  connected_account_id,
  amount,
  source_relation
from charge
where not is_captured
