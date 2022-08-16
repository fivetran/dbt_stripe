with charge as (

    select *
    from {{ var('charge')}}

)

select 
  created_at,
  customer_id,
  amount
from charge
where not is_captured
