with fee as (

    select *
    from `dbt-package-testing`.`stripe`.`fee`

), fields as (

    select 
      balance_transaction_id,
      amount,
      application,
      currency,
      description,
      type
    from fee

)

select *
from fields