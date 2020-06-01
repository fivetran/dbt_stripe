with payout as (

    select *
    from `dbt-package-testing`.`stripe`.`payout`

), fields as (

    select 
      id as payout_id,
      amount,
      arrival_date,
      automatic as is_automatic,
      balance_transaction_id,
      created as created_at,
      currency,
      description,
      method,
      source_type,
      status,
      type
    from payout

)

select *
from fields