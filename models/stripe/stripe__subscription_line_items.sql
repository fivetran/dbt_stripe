{{ config(enabled=fivetran_utils.enabled_vars(['using_invoices','using_subscriptions'])) }}


with line_items as (

  select *
  from {{ ref('stripe__invoice_line_items') }}  
  where subscription_id is not null

)

select *
from line_items
