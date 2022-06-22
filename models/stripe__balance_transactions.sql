with balance_transactions as 
(
    select * 
    from  {{ ref('stripe__balance_transactions_only')}}
), abine_invoice_only as
(
     select * 
    from  {{ ref('stripe__invoice_only')}}
)
select * from balance_transactions
union all
select * from abine_invoice_only