{{
    config(
        materialized='table'
    )
}}

with subscription_mrr as (
	select
		customer_id,
		c."name",
		date_trunc('month', CURRENT_DATE)::date as mrr_month,
		sum(mrr) as mrr,
		round(sum(brl_mrr)::numeric,2) as brl_mrr,
		cm.stripe_account
	from {{ref('stripe__subscription_items_mrr')}} cm 
		left join {{ source('dbt_stripe_account_src', 'customer') }} c on c.id = cm.customer_id
			and c.stripe_account = cm.stripe_account
	group by 1,2,3,6
	order by 1
),
historical_movements as (
	select *,
		row_number() over(partition by customer_id order by mrr_month desc) as mn
	from {{ref('mrr_movements_monthly')}} mmm 
	where mrr_month < date_trunc('month', CURRENT_DATE)::date),
last_brl_value as (
	select 
		hm.customer_id,
		date_trunc('month', hm."date")::Date as mrr_month, 
		round(sum(brl_mrr)::numeric,2) as brl_mrr,
		sum(mrr) as mrr,
		row_number() over(partition by customer_id order by "date" desc) rn,
		stripe_account 
	from {{ref('historical_mrr')}}  hm
	where hm.stripe_account = 'br'
	and mrr <> 0
	group by 1,2, "date", stripe_account
	order by 1,2
),
current_mrr as (
	select
		cm.customer_id,
		cm."name",
		cm.mrr_month,
		case 
			when lbl.brl_mrr = cm.brl_mrr then hm.ending_mrr
			else cm.mrr
		end as mrr,
		cm.stripe_account 
	from subscription_mrr cm
		left join last_brl_value lbl on cm.customer_id = lbl.customer_id
			and lbl.stripe_account = cm.stripe_account
			and lbl.rn = 1
		left join historical_movements hm on cm.customer_id = hm.customer_id and hm.mn = 1
),
current_movement as (
	select 
		cm.customer_id,
		cm."name",
		cm.mrr_month,
		hm.ending_mrr as starting_mrr,
		cm.mrr - hm.ending_mrr as mrr_change,
		cm.mrr as ending_mrr,
		cm.stripe_account
	from current_mrr cm
		left join historical_movements hm on cm.customer_id = hm.customer_id and hm.mn = 1),
event_new as (
	select *, 'New' as event_type
	from current_mrr
	where customer_id not in (select customer_id from historical_movements)),
reactivation as (
	select cm.*,  'Reactivation' as event_type
	from historical_movements hm
		left join current_mrr cm on cm.customer_id = hm.customer_id
	where event_type = 'Churn'
	and mn = 1
	and cm.mrr > 0),
churn_event as (	
	select 
		customer_id,
		"name",
		date_trunc('month', CURRENT_DATE)::date as mrr_month,
		ending_mrr as starting_mrr,
		ending_mrr * -1 as mrr_change,
		0 as ending_mrr,
		'Churn' as event_type,
		stripe_account
	from historical_movements
	where customer_id in (select customer_id from current_mrr where mrr = 0 )
	and (mn = 1 and (event_type <> 'Churn' or event_type is null))
	and date_trunc('year', mrr_month) >= date_trunc('year', CURRENT_DATE)),
final as (
select 
	customer_id,
	"name",
	mrr_month,
	starting_mrr,
	mrr_change,
	ending_mrr,
	case 
		when mrr_change > 0 then 'Upgrade'
		when mrr_change < 0 then 'Downgrade'
	end as event_type,	
	stripe_account
from current_movement
where customer_id not in (select customer_id from reactivation 
union all 
select customer_id from event_new
union all 
select customer_id from churn_event)
union all
select 
	customer_id,
	"name",
	mrr_month,
	0 as starting_mrr,
	mrr as mrr_change,
	mrr as ending_mrr,
	event_type,
	stripe_account
from event_new
union all
select 
	customer_id,
	"name",
	mrr_month,
	0 as starting_mrr,
	mrr as mrr_change,
	mrr as ending_mrr,
	event_type,
	stripe_account
from reactivation
union all
select * 
from churn_event)
select * from final
where starting_mrr > 0
or mrr_change > 0
or ending_mrr > 0
order by 1