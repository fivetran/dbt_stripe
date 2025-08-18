with charge as (

    select *
    from {{ ref('stg_stripe__charge') }}

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
