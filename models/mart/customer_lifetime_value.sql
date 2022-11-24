with active_customers as (
	select date_trunc('month', "date")::date as m_month, count(distinct customer_id) as customer_count, sum(mrr) as mrr, stripe_account 
	from {{ref('historical_mrr')}}  hm 
	where mrr <> 0 
	group by 1,4
	order by 1
),
churn as (
	select date_trunc('month', mrr_month )::date as churn_month, count(customer_id) as customer_count, stripe_account 
	from {{ref('mrr_movements_monthly')}} mmm 
	where event_type = 'Churn'
	group by 1,3
	order by 1
),
general_churn as (
	select 
		churn_month,
		sum(customer_count) as churn_customers
	from churn
	group by 1
	order by 1	
		),
general_mrr as (
	select
		m_month,
		sum(mrr) as mrr,
		sum(ac.customer_count) as customer_count
	from active_customers ac
	group by 1
	order by 1),
general_calc as (
	select m_month,
		sum(mrr) over (order by m_month rows between 2 preceding and current row) as moving_mrr,
		sum(mrr.customer_count) over (order by m_month rows between 2 preceding and current row) as moving_customers,
		sum(c.churn_customers) over (order by c.churn_month rows between 2 preceding and current row) as moving_churn
	from general_mrr mrr
		left join general_churn c on c.churn_month = mrr.m_month),
us_calc as (
	select m_month,
		sum(mrr) over (order by m_month rows between 2 preceding and current row) as moving_mrr,
		sum(ac.customer_count) over (order by m_month rows between 2 preceding and current row) as moving_customers,
		sum(c.customer_count) over (order by c.churn_month rows between 2 preceding and current row) as moving_churn
	from active_customers ac
		left join churn c on c.churn_month = ac.m_month and ac.stripe_account = c.stripe_account
	where ac.stripe_account = 'us'),
br_calc as (
	select m_month,
		sum(mrr) over (order by m_month rows between 2 preceding and current row) as moving_mrr,
		sum(ac.customer_count) over (order by m_month rows between 2 preceding and current row) as moving_customers,
		sum(c.customer_count) over (order by c.churn_month rows between 2 preceding and current row) as moving_churn
	from active_customers ac
		left join churn c on c.churn_month = ac.m_month and ac.stripe_account = c.stripe_account
	where ac.stripe_account = 'br')
select 
	m_month,
	(moving_mrr / moving_customers) / (moving_churn / moving_customers) as ltv,
	'All' as account
from general_calc
union all
select 
	m_month,
	(moving_mrr / moving_customers) / (moving_churn / moving_customers) as ltv,
	'us' as account
from us_calc
union all
select 
	m_month,
	(moving_mrr / moving_customers) / (moving_churn / moving_customers) as ltv,
	'br' as account
from br_calc
order by 1