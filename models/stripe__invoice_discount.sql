WITH invoice_line_item as (

    select *
    from {{ ref('stripe__invoice_line_items') }}

)

select 
  invoice_line_item.invoice_id, 
  max(total) as total, 
  max(subtotal) as subtotal, 
  max(total)::decimal / max(subtotal) as discount_factor
from invoice_line_item
where amount_due > 0
group by invoice_line_item.invoice_id
