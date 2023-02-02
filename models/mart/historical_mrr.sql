{{
    config(
        materialized='table'
    )
}}

with product as (
    select * from {{ref('stripe_product')}}
),  price_region as (
    select * from {{ref('stripe_price_region')}}
), item_location as (
    select * from {{ref('invoice_item_location')}}
),
log_location as (
select distinct 
	il.invoice_id,
	il.item_id,
	il.subscription_item_id,
	il.product_name,
	il.product_class,
	dl.location as location,
	dl.region as region,
    dl.device_count,
	il.stripe_account
	from item_location il
		left join {{ref('netbox_device_history')}} dl on dl.post_subscription_item_id = il.subscription_item_id
where product_class in ('Bare Metal', 'Colocation')
	and il.location is null    
order by 1),
item_info as (
	select * from item_location
	where location is not null or product_class not in ('Bare Metal', 'Colocation')
	union
	select * from log_location),
location_quantity as (
select
	invoice_id,
	item_id,
	subscription_item_id,
	sum(device_count) as quantity
from item_info
group by 1,2,3
order by 1
),
mrr as (
select
        silim.invoice_id,
        silim.customer_id,
        c."name",
        silim.plan_id,
        item_info.item_id,
        item_info.subscription_item_id,
        plan.product_id,
        product_name,
        item_info.product_class,
        price.nickname,
        location,
        region,
        silim.estimated_service_start as invoice_date,
        CASE
            WHEN device_count is not null THEN ((silim.mrr/lq.quantity)*device_count) 
            ELSE silim.mrr
        END as mrr,
        silim.brl_mrr as brl_mrr,
        silim.stripe_account
    from
        {{ref('stripe__invoice_line_items_mrr')}} silim
        left join item_info on item_info.item_id = silim.invoice_line_item_id
        left join {{source('dbt_stripe_account_src', 'customer')}} c on silim.customer_id = c.id
        	and silim.stripe_account = c.stripe_account
        left join {{source('dbt_stripe_account_src', 'plan')}} plan on plan.id = silim.plan_id
        	and silim.stripe_account = plan.stripe_account
        left join {{source('dbt_stripe_account_src', 'price')}} price on plan.id = price.id
        left join location_quantity lq on lq.invoice_id = silim.invoice_id
        	and lq.item_id = silim.invoice_line_item_id
    order by
        invoice_date desc
),
negative_mrr as (
    select  customer_id, 
            date_trunc('month', estimated_service_start)::date as mrr_month, 
            sum(mrr) as mrr_sum, 
            stripe_account
    from {{ref('stripe__invoice_line_items_mrr')}} silim
    group by 1,2,4
    order by 2
)
select
    customer_id,
    "name",
    invoice_id,
    product_name,
    subscription_item_id,
    plan_id,
    product_class,
    location,
    region,
    date_trunc('month', invoice_date) :: date as "date",
    sum(mrr) as mrr,
    sum(brl_mrr) as brl_mrr,
    stripe_account
from
    mrr
where not exists (
    select customer_id , mrr_month
    from negative_mrr nm
        where mrr.customer_id = nm.customer_id 
            and date_trunc('month', mrr.invoice_date)::date = nm.mrr_month
            and nm.mrr_sum < 0
            and nm.stripe_account = mrr.stripe_account)
group by
    1,2,3,4,5,6,7,8,9,10,stripe_account
order by
    "date" desc