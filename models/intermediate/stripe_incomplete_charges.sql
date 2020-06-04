with charge as (

    select *
    from {{ ref('stg_stripe_charge')}}

),

select 
  created_at,
  customer_id,
  amount
from charge
where not captured
