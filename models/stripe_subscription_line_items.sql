{{ config(enabled=var('using_subscriptions', True)) }}


with line_items as (

    select *
    from {{ ref('stripe_invoice_details') }}  
    where subscription_id is not null

)

select 
  *
from line_items
