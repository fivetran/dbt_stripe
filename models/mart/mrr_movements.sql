with mrr_sum as 
	(select 
		row_number() over( partition by customer_id order by estimated_service_start ASC) as mn,
		customer_id,
		date_trunc('day', estimated_service_start)::date as mrr_day,
		sum(mrr) as mrr,
		stripe_account 
	from {{ref('stripe__invoice_line_items_mrr')}} 
	where mrr <> 0
	group by 2,3,stripe_account, estimated_service_start
	order by 2 asc),

mrr_movements as (
	select
		mn,
		customer_id,
		mrr_day,
		coalesce(lag(mrr) over (partition by customer_id order by mrr_day asc),0) as starting_mrr,
		mrr - coalesce(lag(mrr) over (partition by customer_id order by mrr_day asc),0) as mrr_change,
		mrr as ending_mrr,
		stripe_account
	from mrr_sum)

select
	mm.customer_id,
	c."name",
	mm.mrr_day,
	starting_mrr,
	mrr_change,
	ending_mrr,
	case
		when mm.mrr_day = churn.mrr_day then churn.event_type
		when mn = 1 then 'New'
		when mrr_change > 0 then 'Upgrade'
		when mrr_change < 0 then 'Downgrade'
	end as event_type,
	mm.stripe_account
from mrr_movements mm
	left join {{ source('dbt_stripe_account_src', 'customer') }} c on mm.customer_id = c.id and mm.stripe_account = c.stripe_account 
	left join {{ref('mrr_churn')}} churn on churn.customer_id = mm.customer_id
		and churn.mrr_day = mm.mrr_day
		and churn.stripe_account = mm.stripe_account
		and churn.event_type is not null
order by
	mm.customer_id,
	mm.mrr_day asc