with mrr_calc as (
	select	
			customer_id,
			"name",
			date_trunc('month', mrr_day)::date as mrr_month,
			SUM(starting_mrr) as starting_mrr,
			SUM(mrr_change) as mrr_change,
			SUM(ending_mrr) as ending_mrr,
			stripe_account
	from {{ref('mrr_movements')}}
	group by customer_id, "name", stripe_account, mrr_month
	order by customer_id, 3
),
event_new as (
	select distinct
		customer_id,
		date_trunc('month', mrr_day)::date as mrr_month,
		event_type as event_new,
		stripe_account
	from  {{ref('mrr_movements')}}
	where event_type = 'New'
),
churn as (
	select distinct 
		customer_id,
		date_trunc('month', mrr_day)::date as mrr_month,
		event_type as churn_event,
		stripe_account
	from  {{ref('mrr_movements')}}
	where customer_id in (
		select customer_id
		from dbt_data_marts.mrr_movements
		where event_type IN ('churn'))
	and lower(event_type) in ('reactivation', 'churn')
),
mrr_movement as (
	select
		mc.customer_id,
		mc."name",
		mc.mrr_month,
		mc.starting_mrr,
		mc.mrr_change,
		mc.ending_mrr,
		case
			when mc.mrr_month = churn.mrr_month then churn.churn_event
			when mc.mrr_month = "new".mrr_month then "new".event_new
			when mrr_change > 0 then 'Upgrade'
			when mrr_change < 0 then 'Downgrade'
		end as event_type,	
		mc.stripe_account
	from mrr_calc mc
		left join churn on churn.customer_id = mc.customer_id 
			and churn.mrr_month = mc.mrr_month
			and churn.stripe_account = mc.stripe_account
			and churn.churn_event is not null
		left join event_new "new" on "new".customer_id = mc.customer_id 
			and "new".mrr_month = mc.mrr_month
			and "new".stripe_account = mc.stripe_account
			and "new".event_new is not null
)

select * from mrr_movement