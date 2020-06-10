

  create or replace table `dbt-package-testing`.`dbt_erik`.`stripe_invoice_details`
  
  
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

)

select 
  invoice.invoice_id,
  invoice.number,
  invoice.created_at as invoice_created_at,
  invoice.status,
  invoice.due_date,
  invoice.amount_due,
  invoice.subtotal,
  invoice.tax,
  invoice.total,
  invoice.amount_paid,
  invoice.amount_remaining,
  invoice.attempt_count,
  invoice.description as invoice_memo,
  invoice_line_item.description as line_item_desc,
  invoice_line_item.amount as line_item_amount,
  invoice_line_item.quantity,
  charge.balance_transaction_id,
  charge.amount as charge_amount, 
  charge.status as charge_status,
  charge.description as charge_desc,
  charge.created_at as charge_created_at,
  customer.description as customer_description,
  customer.email as customer_email,
  subscription.subscription_id,
  subscription.billing as subcription_billing,
  subscription.start_date as subscription_start_date,
  subscription.ended_at as subscription_ended_at
from invoice
left join charge on charge.charge_id = invoice.charge_id
left join invoice_line_item on invoice.invoice_id = invoice_line_item.invoice_id
left join subscription on invoice_line_item.subscription_id = subscription.subscription_id
left join customer on invoice.customer_id = customer.customer_id
order by invoice.created_at desc
  );
    