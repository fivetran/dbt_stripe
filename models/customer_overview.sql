with balance_transactions_joined as (

    select *
    from {{ ref('stripe_balance_transaction_joined') }}  

), customer as (

    select *
    from {{ ref('stg_stripe_customer') }}  

), transactions_grouped as (
 
  select
    customer_id,
    sum(if(type in ('charge', 'payment'), amount, 0)) as total_sales,
    sum(if(type in ('payment_refund', 'refund'), amount, 0)) as total_refunds,
    sum(amount) as gross_transactions,
    sum(fee) as total_fees,
    sum(net) as net_transactions,
    sum(if(type in ('payment', 'charge'), 1, 0)) as sales_count,
    sum(if(type in ('payment_refund', 'refund'), 1, 0)) as refund_count,    
    sum(if(type in ('charge', 'payment') and date_trunc(date(created_at), month) = date_trunc(current_date(), month),amount,0)) as sales_this_month,
    sum(if(type in ('payment_refund', 'refund') and date_trunc(date(created_at), month) = date_trunc(current_date(), month), amount, 0)) as refunds_this_month,
    sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), amount, 0)) as gross_transactions_this_month,
    sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), fee, 0)) as fees_this_month,
    sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), net, 0)) as net_transactions_this_month,
    sum(if(type in ('payment', 'charge') and date_trunc(date(created_at), month) = date_trunc(current_date(), month) , 1, 0)) as sales_count_this_month,
    sum(if(type in ('payment_refund', 'refund') and date_trunc(date(created_at), month) = date_trunc(current_date(), month) , 1, 0)) as refund_count_this_month,
    min(if(type in ('payment', 'charge'), date(created_at), null)) as first_sale_date,
    max(if(type in ('payment', 'charge'), date(created_at), null)) as most_recent_sale_date
  from balance_transactions_joined
  group by 1, 2

)

select
  coalesce(customer.description, 'No associated customer') as customer_description,
  customer.created_at as customer_created_at,
  customer.is_deliguent,
  total_sales/100.0 as total_sales,
  total_refunds/100.0 as total_refunds,
  gross_transactions/100.0 as gross_transcations,
  total_fees/100.0 as total_fees,
  net_transactions/100.0 as net_trasnactions,
  sales_count,
  refund_count,    
  sales_this_month/100.0 as sales_this_month,
  refunds_this_month/100.0 as refunds_this_month,
  gross_transactions_this_month/100.0 as gross_transactions_this_month,
  fees_this_month/100.0 as fees_this_month,
  net_transactions_this_month/100.0 as net_transactions_this_month,
  sales_count_this_month,
  refund_count_this_month,
  first_sale_date,
  most_recent_sale_date,
  customer.currency as customer_currency,
  customer.default_card_id,
  customer.email,
  customer.shipping_name,
  customer.shipping_address_line_1,
  customer.shipping_address_line_2,
  customer.shipping_address_city,
  customer.shipping_address_state,
  customer.shipping_address_country,
  customer.shipping_address_postal_code,
  customer.shipping_phone
from transactions_grouped
left join customer on transactions_grouped.customer_id = customer.customer_id

