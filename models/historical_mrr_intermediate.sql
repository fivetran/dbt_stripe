with invoice as (
    select *
    from {{ var('invoice') }}  
), invoice_line_item as (
    select *
    from {{ var('invoice_line_item') }}  
), customer as (
    select *
    from {{ var('customer') }}  
), plan as (
    select *
    from {{ var('plan') }}  
)

select
    customer.customer_id,
    --customer.name as customer_name,
    customer.email as customer_email,
    invoice.created_at as invoice_created_at,
    invoice_line_item.unique_id  as invoice_line_item_id,
    invoice_line_item.amount as invoice_line_item_amount,
    coalesce(invoice.tax, 0) as tax,
    plan.plan_interval,
    plan.interval_count,
    case plan.plan_interval
        when 'week' then plan.interval_count * 4
        when 'month' then plan.interval_count
        when 'year' then plan.interval_count / 12.0
    end as subscription_duration_ratio,
    extract(epoch from (invoice.created_at - invoice.created_at + (plan.interval_count || ' MONTH')::INTERVAL)) as estimated_full_service_period,
    extract(epoch from (invoice_line_item.period_end - invoice_line_item.period_start)) as prorated_service_period
from invoice
left join invoice_line_item on invoice.invoice_id = invoice_line_item.invoice_id
left join customer on invoice.customer_id = customer.customer_id
left join plan on invoice_line_item.plan_id = plan.plan_id
