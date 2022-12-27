with mrr_sum_us as 
	(select 
		customer_id,
		date_trunc('day', "date")::date as mrr_day,
		round(sum(mrr)::numeric,2)  as mrr,
		stripe_account 
	from {{ref('historical_mrr')}}  
	where mrr <> 0
	and stripe_account = 'us'
	group by 1,2,stripe_account, "date"
	order by 1 asc),
mrr_sum_br as (
	select *
	from {{ref('brl_fx_variation')}}
),
mrr_movements as (
	select
		row_number() over( partition by customer_id order by mrr_day ASC) as mn,
		customer_id,
		mrr_day,
		coalesce(lag(mrr) over (partition by customer_id order by mrr_day asc),0) as starting_mrr,
		mrr - coalesce(lag(mrr) over (partition by customer_id order by mrr_day asc),0) as mrr_change,
		mrr as ending_mrr,
		stripe_account
	from mrr_sum_us
	where mrr <> 0
	union all
		select
		row_number() over( partition by customer_id order by mrr_day ASC) as mn,
		customer_id,
		mrr_day,
		coalesce(lag(mrr) over (partition by customer_id order by mrr_day asc),0) as starting_mrr,
		mrr - coalesce(lag(mrr) over (partition by customer_id order by mrr_day asc),0) as mrr_change,
		mrr as ending_mrr,
		stripe_account
	from mrr_sum_br
	where mrr <> 0
	),
movements as (
select
	mm.customer_id,
	c."name",
	mm.mrr_day,
	case when mm.mrr_day = churn.mrr_day then 0 
	else starting_mrr end as starting_mrr,
	case when mm.mrr_day = churn.mrr_day then ending_mrr
	else mrr_change end as mrr_change,
	ending_mrr,
	case
		when mm.mrr_day = churn.mrr_day then churn.event_type
		when mm.mn = 1 then 'New'
		when mrr_change > 0 then 'Upgrade'
		when mrr_change < 0 then 'Downgrade'
	end as event_type,
	mm.stripe_account
from mrr_movements mm
	left join {{ source('dbt_stripe_account_src', 'customer') }} c on mm.customer_id = c.id and mm.stripe_account = c.stripe_account
	left join {{ref('mrr_churn')}} churn on churn.customer_id = mm.customer_id
		and churn.mrr_day = mm.mrr_day
		and churn.stripe_account = mm.stripe_account
		and churn.event_type = 'Reactivation'),
final as (
select * from movements 
union all
select
	churn.customer_id,
	c."name",
	churn.mrr_day,
	ud.ending_mrr as starting_mrr,
	ud.ending_mrr * -1 as mrr_change,
	0 as ending_mrr,
	churn.event_type,
	churn.stripe_account
from {{ref('mrr_churn')}} churn
	left join movements ud on ud.customer_id = churn.customer_id
		and (ud.mrr_day+ INTERVAL '1 month')::date = churn.mrr_day
	left join {{ source('dbt_stripe_account_src', 'customer') }} c on churn.customer_id = c.id and churn.stripe_account = c.stripe_account
where churn.event_type = 'Churn'
)
select *
from final
order by customer_id, mrr_day, starting_mrr asc, event_type desc, ending_mrr desc