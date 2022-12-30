{{
    config(
        materialized='table'
    )
}}

with product as (
    select
        p.id,
        p.name,
        p.created,
        pc."name" as product_class
    from
        {{source('dbt_stripe_account_src', 'product')}} p
        left join {{source('dbt_stripe_account_src', 'product_classes')}} pc on p.product_class = pc.id),    
device as (
    select
        json_extract_path_text(custom_field_data, 'subscription_item_id') as item_id,
        site_id,
        created,
        row_number() over (
            partition by json_extract_path_text(custom_field_data, 'subscription_item_id')
            order by
                json_extract_path_text(custom_field_data, 'subscription_item_id'),
                created desc
        ) rn
    from
        {{source('ft_netbox_public', 'dcim_device')}}
),
price_location as (
    select
        distinct price.id,
        nickname,
        case
            when lower(nickname) ilike '%brazil%' then 'Brazil'
            when lower(nickname) ilike '%australia%' then 'Australia'
            when lower(nickname) ilike '%japan%' then 'Japan'
            when lower(nickname) ilike '%united-states%' then 'United States'
            when lower(nickname) ilike '%united states%' then 'United States'
            when lower(nickname) ilike '%argentina%' then 'Argentina'
            when lower(nickname) ilike '%chile%' then 'Chile'
            when lower(nickname) ilike '%mexico%' then 'Mexico'
            when lower(nickname) ilike '%new york%' then 'United States'
            when lower(nickname) ilike '%united-kingdom%' then 'United Kingdom'
            when lower(nickname) ilike '%colombia%' then 'Colombia'
            when lower(nickname) ilike '%USA%' then 'United States'
            when lower(nickname) ilike '%us%' and p.product_class  = 'Bandwidth' then 'United States'
        end as price_local,
        p.product_class
    from
        {{source('dbt_stripe_account_src', 'price')}} price
        left join product p on p.id = price.product_id 
),
item_info as (
    select
        ili.invoice_id,
        ili.unique_id item_id,
        ili.subscription_item_id,
        p2."name" as product_name,
        p2.product_class,
        site."name" as site_name,
        price_local,
        ili.stripe_account,
        count(d.rn)
    from
        {{source('dbt_stripe_account_src', 'invoice_line_item')}} ili
        left join device d on d.item_id = ili.subscription_item_id and d.item_id is not null
        left join {{source('ft_netbox_public', 'dcim_site')}} site on d.site_id = site.id
        left join {{source('dbt_stripe_account_src', 'price')}} p on ili.price_id = p.id
        left join product p2 on p.product_id = p2.id
        left join price_location pl on pl.id = ili.price_id
    group by 1,2,3,4,5,6,7,8
),
location_quantity as (
select
	invoice_id,
	item_id,
	subscription_item_id,
	count(*) as quantity
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
        coalesce(site_name, price_local) as site_name,
        silim.estimated_service_start as invoice_date,
        (silim.mrr/lq.quantity) as mrr,
        silim.brl_mrr as brl_mrr,
        silim.stripe_account
    from
        {{ref('stripe__invoice_line_items_mrr')}} silim
        left join item_info on item_info.item_id = silim.invoice_line_item_id
        left join {{source('dbt_stripe_account_src', 'customer')}} c on silim.customer_id = c.id
        	and silim.stripe_account = c.stripe_account
        left join {{source('dbt_stripe_account_src', 'plan')}} plan on plan.id = silim.plan_id
        	and silim.stripe_account = plan.stripe_account
        left join product p on plan.product_id = p.id
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
    from "defaultdb"."dbt_aoliveira_stripe"."stripe__invoice_line_items_mrr" silim
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
    site_name,
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
    1,2,3,4,5,6,7,8,9,12
order by
    "date" desc