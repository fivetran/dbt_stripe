with balance_transaction_joined as (

    select *
    from {{ ref('stripe_balance_transaction_joined') }}  

), incomplete_charges as (

    select *
    from {{ ref('stripe_incomplete_charges') }}  

), customer as (

    select *
    from {{ ref('stg_stripe_customer') }}  

), transaction_grouped as (
 
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
  from balance_transaction_joined
    where type in ('payment', 'charge', 'payment_refund', 'refund')
  group by 1

), failed_charges_by_customer (

    select
      customer_id,
      count(*) as number_failed_charges
      sum(amount) as total_failed_charge_amount
    from incomplete_charges

)

select
  coalesce(customer.description, customer.customer_id, 'No associated customer') as customer_description,
  customer.email,
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
  number_failed_charges,
  total_failed_charge_amount/100 as total_failed_charge_amount,
  customer.currency as customer_currency,
  customer.default_card_id,
  customer.shipping_name,
  customer.shipping_address_line_1,
  customer.shipping_address_line_2,
  customer.shipping_address_city,
  customer.shipping_address_state,
  customer.shipping_address_country,
  customer.shipping_address_postal_code,
  customer.shipping_phone
from customer
left join transaction_grouped on transaction_grouped.customer_id = customer.customer_id
left join failed_charges_by_customer on customer.customer_id = failed_charges_by_customer.customer_id

