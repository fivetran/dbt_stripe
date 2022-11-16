with customer_count as (
	select 
		date_trunc('month', "date")::date as mrr_month, 
		count(distinct customer_id) as customers,
		stripe_account 
	from {{ref('historical_mrr')}} 
	where mrr > 0
	group by 1,3
	order by 1),
mrr_sum as (
	select
		date_trunc('month', "date")::date as mrr_month,
		sum(mrr) as mrr,
		stripe_account 
	from {{ref('historical_mrr')}} 
	where mrr <> 0
	group by 1,3
	order by 1),
general_average as (
	select
		ms.mrr_month,
		sum(ms.mrr)/sum(customers) as average_revenue,
		sum(customers) as customers,
		'All' as stripe_account 
		from mrr_sum ms
			left join customer_count cc on ms.mrr_month = cc.mrr_month
                and ms.stripe_account = cc.stripe_account
		group by 1,4
		order by 1 asc),
account_average as (
	select
		ms.mrr_month,
		ms.mrr/customers as average_revenue,
		customers,
		ms.stripe_account
		from mrr_sum ms
			left join customer_count cc on ms.mrr_month = cc.mrr_month
				and ms.stripe_account = cc.stripe_account
	order by 1 asc)
select * 
from general_average
union all
select * 
from account_average