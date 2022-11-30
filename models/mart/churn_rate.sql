with churn_count as (
    select 
        churn_month,
        count(customer_id) as customer_count,
        stripe_account
    from {{ref('churn')}}
    group by 1,3
    order by 1
),
active_customers as (
	select 
        date_trunc('month', "date")::date as m_month, 
        count(distinct customer_id) as customer_count, 
        stripe_account 
	from {{ref('historical_mrr')}}  hm 
	where mrr <> 0 
		-- Removing test accounts
		and customer_id NOT IN ('cus_MVjwgFklliUF9p','cus_J8IS1IGMxzZLzR')
	group by 1,3
	order by 1
),
general_churn as (
	select 
		churn_month,
		sum(customer_count) as churn_customers,
        stripe_account
	from churn_count
	group by 1,3
	order by 1	
),
general_calc as (
	select 
        m_month,
		sum(c.churn_customers) / sum(customer_count) as churn_rate
	from active_customers ac
		left join general_churn c on c.churn_month = ac.m_month
    group by 1
),
us_calc as (
	select 
        m_month,
		sum(c.churn_customers) / sum(customer_count) as churn_rate
	from active_customers ac
		left join general_churn c on c.churn_month = ac.m_month and ac.stripe_account = c.stripe_account
	where ac.stripe_account = 'us'
    group by 1
),
br_calc as (
	select 
        m_month,
		sum(c.churn_customers) / sum(customer_count) as churn_rate
	from active_customers ac
		left join general_churn c on c.churn_month = ac.m_month and ac.stripe_account = c.stripe_account
	where ac.stripe_account = 'br'
    group by 1
)

select 
	m_month,
	churn_rate,
	'All' as account
from general_calc
union all
select 
	m_month,
	churn_rate,
	'us' as account
from us_calc
union all
select 
	m_month,
	churn_rate,
	'br' as account
from br_calc
order by 1