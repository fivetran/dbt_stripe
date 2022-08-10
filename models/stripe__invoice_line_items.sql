{{ config(enabled=var('using_invoices', True)) }}

with invoice as (

    select *
    from {{ var('invoice') }}

), charge as (

    select *
    from {{ var('charge') }}

), invoice_line_item as (

    select *
    from {{ var('invoice_line_item') }}

), customer as (

    select *
    from {{ ref('stripe__customer') }}

{% if var('using_subscriptions', True) %}

), subscription as (

    select *
    from {{ var('subscription') }}

), plan as (

    select *
    from {{ var('plan') }}

{% endif %}
)

select
    invoice.invoice_id,
    invoice.number,
    invoice.created_at as invoice_created_at,
    invoice.status,
    invoice.due_date,
    invoice.amount_due,
    invoice.subtotal,
    coalesce(invoice.tax, 0) as tax,
    invoice.total,
    invoice.amount_paid,
    invoice.amount_remaining,
    invoice.attempt_count,
    invoice.description as invoice_memo,
    invoice_line_item.unique_id  as invoice_line_item_id,
    invoice_line_item.description as line_item_desc,
    invoice_line_item.amount as line_item_amount,
    invoice_line_item.is_discountable as discountable,
    invoice_line_item.quantity,
    invoice_line_item.period_start,
    invoice_line_item.period_end,
    charge.balance_transaction_id,
    charge.amount as charge_amount,
    charge.status as charge_status,
    charge.created_at as charge_created_at,
    customer.description as customer_description,
    customer.email as customer_email,
    customer.customer_id

    {% if var('using_subscriptions', True) %}
    ,invoice_line_item.proration,
    case plan.plan_interval
        when 'week' then plan.interval_count * 4
        when 'month' then plan.interval_count
        when 'year' then plan.interval_count / 12.0
    end as subscription_duration_ratio,
    case
        when invoice_line_item.proration
        then
            invoice_line_item.period_end - (plan.interval_count || ' ' || plan.plan_interval)::INTERVAL
        else
            invoice_line_item.period_start
    end as estimated_service_start,
    case
        when invoice_line_item.proration 
        then
            extract(
                epoch from (
                    invoice_line_item.period_end -
                    (invoice_line_item.period_end - (plan.interval_count || ' ' || plan.plan_interval)::INTERVAL)
                )
            )
        else
            extract(epoch from (invoice_line_item.period_end - invoice_line_item.period_start))
    end as estimated_full_service_period,
    extract(epoch from (invoice_line_item.period_end - invoice_line_item.period_start)) as prorated_service_period,
    subscription.subscription_id,
    subscription.billing as subscription_billing,
    subscription.start_date as subscription_start_date,
    subscription.ended_at as subscription_ended_at,
    plan.plan_id,
    plan.is_active as plan_is_active,
    plan.amount as plan_amount,
    plan.plan_interval as plan_interval,
    plan.interval_count as plan_interval_count,
    plan.nickname as plan_nickname,
    plan.product_id as plan_product_id,
    customer.stripe_account
    {% endif %}

from invoice

left join charge
    on charge.charge_id = invoice.charge_id
left join invoice_line_item
    on invoice.invoice_id = invoice_line_item.invoice_id
{% if var('using_subscriptions', True) %}
left join subscription
    on invoice.subscription_id = subscription.subscription_id
left join plan
    on invoice_line_item.plan_id = plan.plan_id
{% endif %}
left join customer
    on invoice.customer_id = customer.customer_id

{% if var('using_subscriptions', True) %}
where
    subscription.subscription_id IS NOT NULL
{% endif %}
