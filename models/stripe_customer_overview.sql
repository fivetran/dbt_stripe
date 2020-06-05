with balance_transaction_joined as (

    select *
    from {{ ref('stripe_balance_transaction_joined') }}  

), incomplete_charges as (

    select *
    from {{ ref('stripe_incomplete_charges') }}  

), customer as (

    select *
    from {{ ref('stg_stripe_customer') }}  

), transactions_grouped as (
 
    select
      customer_id,
      sum(if(type in ('charge', 'payment'), amount, 0)) as total_sales,
      sum(if(type in ('payment_refund', 'refund'), amount, 0)) as total_refunds,
      sum(amount) as total_gross_transaction_amount,
      sum(fee) as total_fees,
      sum(net) as total_net_transaction_amount,
      sum(if(type in ('payment', 'charge'), 1, 0)) as total_sales_count,
      sum(if(type in ('payment_refund', 'refund'), 1, 0)) as total_refund_count,    
      sum(if(type in ('charge', 'payment') and date_trunc(date(created_at), month) = date_trunc(current_date(), month),amount, 0)) as sales_this_month,
      sum(if(type in ('payment_refund', 'refund') and date_trunc(date(created_at), month) = date_trunc(current_date(), month), amount, 0)) as refunds_this_month,
      sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), amount, 0)) as gross_transaction_amount_this_month,
      sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), fee, 0)) as fees_this_month,
      sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), net, 0)) as net_transaction_amount_this_month,
      sum(if(type in ('payment', 'charge') and date_trunc(date(created_at), month) = date_trunc(current_date(), month) , 1, 0)) as sales_count_this_month,
      sum(if(type in ('payment_refund', 'refund') and date_trunc(date(created_at), month) = date_trunc(current_date(), month) , 1, 0)) as refund_count_this_month,
      min(if(type in ('payment', 'charge'), date(created_at), null)) as first_sale_date,
      max(if(type in ('payment', 'charge'), date(created_at), null)) as most_recent_sale_date
    from balance_transaction_joined
      where type in ('payment', 'charge', 'payment_refund', 'refund')
    group by 1

), failed_charges_by_customer as (

    select
      customer_id,
      count(*) as total_failed_charge_count,
      sum(amount) as total_failed_charge_amount,
      sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), 1, 0)) as failed_charge_count_this_month,
      sum(if(date_trunc(date(created_at), month) = date_trunc(current_date(), month), amount, 0)) as failed_charge_amount_this_month
    from incomplete_charges
    group by 1

)

select
  coalesce(customer.description, customer.customer_id, 'No associated customer') as customer_description,
  customer.email,
  customer.created_at as customer_created_at,
  customer.is_deliguent,
  coalesce(transactions_grouped.total_sales/100.0, 0) as total_sales,
  coalesce(transactions_grouped.total_refunds/100.0, 0) as total_refunds,
  coalesce(transactions_grouped.total_gross_transaction_amount/100.0, 0) as total_gross_transcation_amount,
  coalesce(transactions_grouped.total_fees/100.0, 0) as total_fees,
  coalesce(transactions_grouped.total_net_transaction_amount/100.0, 0) as total_net_trasnaction_amount,
  coalesce(transactions_grouped.total_sales_count, 0) as total_sales_count,
  coalesce(transactions_grouped.total_refund_count, 0) as total_refund_count,    
  coalesce(transactions_grouped.sales_this_month/100.0, 0) as sales_this_month,
  coalesce(transactions_grouped.refunds_this_month/100.0, 0) as refunds_this_month,
  coalesce(transactions_grouped.gross_transaction_amount_this_month/100.0, 0) as gross_transaction_amount_this_month,
  coalesce(transactions_grouped.fees_this_month/100.0, 0) as fees_this_month,
  coalesce(transactions_grouped.net_transaction_amount_this_month/100.0, 0) as net_transaction_amount_this_month,
  coalesce(transactions_grouped.sales_count_this_month, 0) as sales_count_this_month,
  coalesce(transactions_grouped.refund_count_this_month, 0) as refund_count_this_month,
  transactions_grouped.first_sale_date,
  transactions_grouped.most_recent_sale_date,
  coalesce(total_failed_charge_count, 0) as total_failed_charge_count,
  coalesce(total_failed_charge_amount/100, 0) as total_failed_charge_amount,
  coalesce(failed_charge_count_this_month, 0) as failed_charge_count_this_month,
  coalesce(failed_charge_amount_this_month/100, 0) as failed_charge_amount_this_month,
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
left join transactions_grouped on transactions_grouped.customer_id = customer.customer_id
left join failed_charges_by_customer on customer.customer_id = failed_charges_by_customer.customer_id

