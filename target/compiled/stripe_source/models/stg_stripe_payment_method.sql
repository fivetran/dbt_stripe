

with payment_method as (

    select *
    from `dbt-package-testing`.`stripe`.`payment_method`

), fields as (

    select 
      id as payment_method_id,
      created as created_at,
      customer_id,
      type
    from payment_method
    where not is_deleted

)

select *
from fields