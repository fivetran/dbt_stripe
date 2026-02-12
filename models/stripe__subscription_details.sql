{{ config(enabled=fivetran_utils.enabled_vars(['stripe__using_invoices','stripe__using_subscriptions'])) }}

with invoice as (

   select *
   from {{ ref('stg_stripe__invoice') }}

), charge as (

   select *
   from {{ ref('stg_stripe__charge') }}

), invoice_line_item as (

    select *
    from {{ ref('stg_stripe__invoice_line_item') }}

), subscription as (

   select *
   from {{ ref('stg_stripe__subscription') }}

), subscription_item as (

    select *
    from {{ ref('int_stripe__deduped_subscription_item') }}

), customer as (

   select *
   from {{ ref('stg_stripe__customer') }} 

), line_items_groups as (

   select
     invoice.invoice_id,
     invoice.amount_due,
     invoice.amount_paid,
     invoice.amount_remaining,
     invoice.created_at,
     invoice.source_relation,
     max(invoice_line_item.subscription_id) as subscription_id,
     coalesce(sum(invoice_line_item.amount),0) as total_line_item_amount,
     coalesce(count(distinct invoice_line_item.unique_invoice_line_item_id),0) as number_of_line_items
   from invoice_line_item
   join invoice
     on invoice.invoice_id = invoice_line_item.invoice_id
   group by 1, 2, 3, 4, 5, 6

), grouped_by_subscription as (

   select
     subscription_id,
     source_relation,
     count(distinct invoice_id) as number_invoices_generated,
     sum(amount_due) as total_amount_billed,
     sum(amount_paid) as total_amount_paid,
     sum(amount_remaining) total_amount_remaining,
     max(created_at) as most_recent_invoice_created_at,
     avg(amount_due) as average_invoice_amount,
     avg(total_line_item_amount) as average_line_item_amount,
     avg(number_of_line_items) as avg_num_line_items
   from line_items_groups
   group by 1, 2

)


 select
   subscription.subscription_id,
   subscription.customer_id,
   customer.description as customer_description,
   customer.email as customer_email,
   {{ stripe.select_metadata_columns('customer', 'stripe__customer_metadata') }}
   subscription.status,
   subscription.start_date_at,
   subscription.ended_at,
   subscription.billing,
   subscription.billing_cycle_anchor,
   subscription.canceled_at,
   subscription.created_at,
   --Newer Stripe connections will store current_period_start/end fields in SUBSCRIPTION_ITEM while older ones house these fields in SUBSCRIPTION_HISTORY -> grab both and coalesce
   coalesce(subscription.current_period_start, subscription_item.current_period_start) as current_period_start,
   coalesce(subscription.current_period_end, subscription_item.current_period_end) as current_period_end,
   subscription.days_until_due,
   subscription.is_cancel_at_period_end,
   subscription.cancel_at,
   {{ stripe.select_metadata_columns('subscription', 'stripe__subscription_metadata') }}
   number_invoices_generated,
   total_amount_billed,
   total_amount_paid,
   total_amount_remaining,
   most_recent_invoice_created_at,
   average_invoice_amount,
   average_line_item_amount,
   avg_num_line_items,
   subscription.source_relation
 from subscription
 left join subscription_item
   on subscription.subscription_id = subscription_item.subscription_id
   and subscription.source_relation = subscription_item.source_relation
 left join grouped_by_subscription 
   on subscription.subscription_id = grouped_by_subscription.subscription_id
   and subscription.source_relation = grouped_by_subscription.source_relation
 left join customer
   on subscription.customer_id = customer.customer_id
   and subscription.source_relation = customer.source_relation
