{{ config(enabled=fivetran_utils.enabled_vars(['stripe__using_invoices','stripe__using_subscriptions'])) }}


with line_items as (

  select *
  from {{ ref('stripe__invoice_details') }}  
  where subscription_id is not null

)

select *
from line_items
