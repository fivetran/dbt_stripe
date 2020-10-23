{{ config(enabled=var('using_subscriptions', True)) }}


with line_items as (

    select *
    from {{ ref('stripe__invoice_line_items') }}  
    where subscription_id is not null

)

select 
  *
from line_items
