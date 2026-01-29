{{ config(enabled=var('stripe__using_invoices', True)) }}

{% set charge_cols = adapter.get_columns_in_relation(ref('stg_stripe__charge')) | map(attribute='name') | list %}
{% set invoice_cols = adapter.get_columns_in_relation(ref('stg_stripe__invoice')) | map(attribute='name') | list %}
{% set subscription_cols = adapter.get_columns_in_relation(ref('stg_stripe__subscription')) | map(attribute='name') | list %}
{% set customer_cols = adapter.get_columns_in_relation(ref('stg_stripe__customer')) | map(attribute='name') | list %}

with invoice as (

   select
      invoice.*
      {% for metadata in var('stripe__invoice_metadata', []) %}
        {% if metadata in invoice_cols %}
          , invoice.{{ metadata }} as invoice_{{ metadata }}
        {% else %}
        {% endif %}
      {% endfor %}
   from {{ ref('stg_stripe__invoice') }} as invoice

), charge as (

   select
      charge.*
      {% for metadata in var('stripe__charge_metadata', []) %}
        {% if metadata in charge_cols %}
          , charge.{{ metadata }} as charge_{{ metadata }}
        {% else %}
        {% endif %}
      {% endfor %}
   from {{ ref('stg_stripe__charge') }} as charge

), invoice_line_item as (

    select
        invoice_id,
        source_relation,
        coalesce(count(distinct unique_invoice_line_item_id),0) as number_of_line_items,
        coalesce(sum(quantity),0) as total_quantity

    from {{ ref('stg_stripe__invoice_line_item') }}
    group by 1,2

), customer as (

   select
      customer.*
      {% for metadata in var('stripe__customer_metadata', []) %}
        {% if metadata in customer_cols %}
          , customer.{{ metadata }} as customer_{{ metadata }}
        {% else %}
        {% endif %}
      {% endfor %}
   from {{ ref('stg_stripe__customer') }} as customer

{% if var('stripe__using_subscriptions', True) %}

), subscription as (

   select
      subscription.*
      {% for metadata in var('stripe__subscription_metadata', []) %}
        {% if metadata in subscription_cols %}
          , subscription.{{ metadata }} as subscription_{{ metadata }}
        {% else %}
        {% endif %}
      {% endfor %}
   from {{ ref('stg_stripe__subscription') }} as subscription  

), price_plan as (

    select *
    from {{ ref('stg_stripe__price_plan') }}  

{% endif %}
)

select
    invoice.invoice_id,
    invoice.number as invoice_number,
    invoice.created_at as invoice_created_at,
    invoice.period_start,
    invoice.period_end,
    invoice.status,
    invoice.due_date,
    invoice.currency,
    coalesce(invoice.amount_due,0) as amount_due,
    coalesce(invoice.amount_paid,0) as amount_paid,
    coalesce(invoice.subtotal,0) as subtotal,
    coalesce(invoice.tax,0) as tax,
    coalesce(invoice.total,0) as total,
    coalesce(invoice.amount_remaining,0) as amount_remaining,
    coalesce(invoice.attempt_count,0) as attempt_count,
    invoice.description as invoice_memo,
    {% for metadata in var('stripe__invoice_metadata', []) %}
      {% if metadata in invoice_cols %}
        invoice.invoice_{{ metadata }} as invoice_{{ metadata }},
      {% endif %}
    {% endfor %}
    invoice_line_item.number_of_line_items,
    invoice_line_item.total_quantity,
    charge.balance_transaction_id,
    charge.amount as charge_amount,
    charge.status as charge_status,
    charge.connected_account_id,
    charge.created_at as charge_created_at,
    charge.is_refunded as charge_is_refunded,
    {% for metadata in var('stripe__charge_metadata', []) %}
      {% if metadata in charge_cols %}
        charge.charge_{{ metadata }} as charge_{{ metadata }},
      {% endif %}
    {% endfor %}
    customer.customer_id,
    customer.description as customer_description,
    customer.account_balance as customer_account_balance,
    customer.currency as customer_currency,
    customer.is_delinquent as customer_is_delinquent,
    customer.email as customer_email,
    {% for metadata in var('stripe__customer_metadata', []) %}
      {% if metadata in customer_cols %}
        customer.customer_{{ metadata }} as customer_{{ metadata }},
      {% endif %}
    {% endfor %}

    {% if var('stripe__using_subscriptions', True) %}
    subscription.subscription_id,
    subscription.billing as subscription_billing,
    subscription.start_date_at as subscription_start_date,
    subscription.ended_at as subscription_ended_at,
    {% for metadata in var('stripe__subscription_metadata', []) %}
      {% if metadata in subscription_cols %}
        subscription.subscription_{{ metadata }} as subscription_{{ metadata }},
      {% endif %}
    {% endfor %}

    {% endif %}
    invoice.source_relation

from invoice

left join invoice_line_item 
    on invoice.invoice_id = invoice_line_item.invoice_id
    and invoice.source_relation = invoice_line_item.source_relation

left join charge 
    on invoice.charge_id = charge.charge_id
    and invoice.invoice_id = charge.invoice_id
    and invoice.source_relation = charge.source_relation

{% if var('stripe__using_subscriptions', True) %}
left join subscription
    on invoice.subscription_id = subscription.subscription_id
    and invoice.source_relation = subscription.source_relation

{% endif %}

left join customer 
    on invoice.customer_id = customer.customer_id
    and invoice.source_relation = customer.source_relation