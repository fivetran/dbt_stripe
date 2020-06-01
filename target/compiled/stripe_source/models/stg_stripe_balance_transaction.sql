with balance_transaction as (

    select *
    from `dbt-package-testing`.`stripe`.`balance_transaction`

), fields as (

    select 
      id as balance_transaction_id,
      amount,
      available_on,
      created as created_at,
      currency,
      description,
      exchange_rate,
      fee,
      net,
      source,
      status,
      type
    from balance_transaction
)

select *
from fields