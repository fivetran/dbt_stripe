

  create or replace table `dbt-package-testing`.`dbt_erik`.`stripe_subscription_details`
  
  
  OPTIONS()
  as (
    

with  __dbt__CTE__stg_stripe_invoice as (


with invoice as (

    select *
    from `dbt-package-testing`.`stripe`.`invoice`

), fields as (

    select
      id as invoice_id,
      amount_due,
      amount_paid,
      amount_remaining,
      attempt_count,
      auto_advance,
      billing_reason,
      charge_id,
      created as created_at,
      currency,
      customer_id,
      description,
      due_date,
      number,
      paid as is_paid,
      receipt_number,
      status,
      subtotal,
      tax,
      tax_percent,
      total
    from invoice
    where not coalesce(is_deleted, false)

)

select * from fields
),  __dbt__CTE__stg_stripe_charge as (
with charge as (

    select *
    from `dbt-package-testing`.`stripe`.`charge`

), fields as (

    select 
      id as charge_id, 
      amount,
      amount_refunded,
      application_fee_amount,
      balance_transaction_id,
      captured as is_captured,
      card_id,
      created as created_at,
      customer_id,
      currency,
      description,
      failure_code,
      failure_message,
      paid as is_paid,
      payment_intent_id,
      receipt_email,
      receipt_number,
      refunded as is_refunded,
      status,
      invoice_id
    from charge
    
)

select *
from fields
),  __dbt__CTE__stg_stripe_invoice_line_item as (


with invoice_line_item as (

    select *
    from `dbt-package-testing`.`stripe`.`invoice_line_item`

), fields as (

    select
      id as invoice_line_item_id,
      invoice_id,
      amount,
      currency,
      description,
      discountable as is_discountable,
      plan_id,
      proration,
      quantity,
      subscription_id,
      subscription_item_id,
      type,
      unique_id
    from invoice_line_item
    where id not like 'sub%'

)

select * from fields
),  __dbt__CTE__stg_stripe_subscription as (


with subscription as (

    select *
    from `dbt-package-testing`.`stripe`.`subscription`

), fields as (

    select
      id as subscription_id,
      status,
      billing,
      billing_cycle_anchor,
      cancel_at,
      cancel_at_period_end,
      canceled_at,
      created as created_at,
      current_period_start,
      current_period_end,
      customer_id,
      days_until_due,
      start_date,
      ended_at
    from subscription

)

select * from fields
),  __dbt__CTE__stg_stripe_customer as (
with customer as (

    select *
    from `dbt-package-testing`.`stripe`.`customer`

), fields as (

    select 
      id as customer_id,
      account_balance,
      created as created_at,
      currency,
      default_card_id,
      delinquent as is_deliguent,
      description,
      email,
      shipping_address_city,
      shipping_address_country,
      shipping_address_line_1,
      shipping_address_line_2,
      shipping_address_postal_code,
      shipping_address_state,
      shipping_name,
      shipping_phone
    from customer
    where not is_deleted

)

select *
from fields
),invoice as (

    select *
    from __dbt__CTE__stg_stripe_invoice  

), charge as (

    select *
    from __dbt__CTE__stg_stripe_charge  

), invoice_line_item as (

    select *
    from __dbt__CTE__stg_stripe_invoice_line_item  

), subscription as (

    select *
    from __dbt__CTE__stg_stripe_subscription  

), customer as (

    select *
    from __dbt__CTE__stg_stripe_customer  

), line_items_groups as (

  select
    invoice.invoice_id,
    invoice.amount_due,
    invoice.amount_paid,
    invoice.amount_remaining,
    invoice.created_at,
    max(invoice_line_item.subscription_id) as subscription_id,
    sum(invoice_line_item.amount) as total_item_amount,
    count(distinct invoice_line_item.unique_id) as number_line_items
  from invoice_line_item
  join invoice on invoice.invoice_id = invoice_line_item.invoice_id
  group by 1, 2, 3, 4, 5

), grouped_by_subcription as (

  select
    subscription_id,
    count(distinct invoice_id) as number_invoices_generated,
    sum(amount_due) as total_amount_billing,
    sum(amount_paid) as total_amount_paid,
    sum(amount_remaining) total_amount_remaining,
    max(created_at) as most_recent_invoice_created_at,
    avg(amount_due) as average_invoice_amount,
    avg(total_item_amount) as average_line_item_amount,
    avg(number_line_items) as avg_num_invoice_items
  from line_items_groups
  group by 1

)


select
  subscription.subscription_id,
  subscription.customer_id,
  customer.description as customer_description,
  customer.email as customer_email,
  subscription.status,
  subscription.start_date,
  subscription.ended_at,
  subscription.billing,
  subscription.billing_cycle_anchor,
  subscription.canceled_at,
  subscription.created_at,
  subscription.current_period_start,
  subscription.current_period_end,
  subscription.days_until_due,
  subscription.cancel_at_period_end,
  subscription.cancel_at,
  number_invoices_generated,
  total_amount_billing,
  total_amount_paid,
  total_amount_remaining,
  most_recent_invoice_created_at,
  average_invoice_amount,
  average_line_item_amount,
  avg_num_invoice_items
from subscription
left join grouped_by_subcription on subscription.subscription_id = grouped_by_subcription.subscription_id
left join customer on subscription.customer_id = customer.customer_id
order by subscription.created_at desc
  );
    