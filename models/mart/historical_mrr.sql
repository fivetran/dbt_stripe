with product as (
select
	id,
	name,
	created
from
	{{source('dbt_stripe_account_src', 'product')}}
where
	active = true
),
device as (
select 
	json_extract_path_text(custom_field_data,
	'subscription_item_id') as item_id,
	site_id,
	created,
	row_number() over (partition by json_extract_path_text(custom_field_data,
	'subscription_item_id')
order by
	json_extract_path_text(custom_field_data,
	'subscription_item_id'),
	created desc) rn
from
	{{source('ft_netbox_public', 'dcim_device')}}
),
item_info as (
select
	ili.invoice_id,
	ili.unique_id item_id,
	ili.subscription_item_id,
	p2."name" as product_name, 
	site.name as site_name,
	ili.stripe_account 
from
	{{source('dbt_stripe_account_src', 'invoice_line_item')}} ili
left join device d on
	d.item_id = ili.subscription_item_id
	and d.rn = 1
left join {{source('ft_netbox_public', 'dcim_site')}} site on
	d.site_id = site.id
left join {{source('dbt_stripe_account_src', 'price')}} p on
	ili.price_id = p.id
left join {{source('dbt_stripe_account_src', 'product')}} p2 on
	p.product_id = p2.id),
price_location as (select distinct id, nickname,
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
	end as price_local
from {{source('dbt_stripe_account_src', 'price')}}
),
mrr as (
select 
	silim.invoice_id,
	silim.customer_id,
	c."name",
	silim.plan_id,
	item_id,
	item_info.subscription_item_id,
	product_name,
	price.nickname,
	coalesce(site_name,pl.price_local) as site_name,
	silim.invoice_created_at as invoice_date,
	CASE WHEN silim.stripe_account = 'us' THEN (silim.mrr/100)
	ELSE silim.mrr
	END as mrr,
	silim.stripe_account
from
	{{ref('stripe__invoice_line_items_mrr')}} silim
left join item_info  on
	item_info.item_id = silim.invoice_line_item_id
left join {{source('dbt_stripe_account_src', 'customer')}} c on
	silim.customer_id = c.id and silim.stripe_account = c.stripe_account 
left join {{source('dbt_stripe_account_src', 'plan')}} plan on
	plan.id = silim.plan_id and silim.stripe_account = plan.stripe_account 
left join product p on
	plan.product_id = p.id
left join {{source('dbt_stripe_account_src', 'price')}} price on plan.id = price.id
left join price_location pl on pl.id = silim.plan_id
order by
	invoice_date desc
)
select 
	customer_id,
	"name",
	invoice_id,
	product_name,
	site_name,
	date_trunc('month', invoice_date)::date as "date",
	sum(mrr) as mrr,
	stripe_account
from
	mrr
group by
	1,2,3,4,5,6,8
order by
	"date" desc