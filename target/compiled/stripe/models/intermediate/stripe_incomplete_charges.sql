with charge as (

    select *
    from `dbt-package-testing`.`dbt_kristin_2`.`stg_stripe_charge`

)

select 
  created_at,
  customer_id,
  amount
from charge
where not is_captured