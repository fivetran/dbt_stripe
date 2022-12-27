with mrr_calc as (
    select
        row_number() over(
            partition by customer_id
            order by
                "date" desc
        ) as mn,
        silim.customer_id,
        date_trunc('day', silim."date") :: date as mrr_day,
        round(sum(mrr)::numeric, 2) as mrr,
        case
            p."interval"
            when 'week' then p.interval_count * 7
            when 'month' then p.interval_count * 30
            when 'year' then p.interval_count * 365
        end as plan_period_in_days,
        silim.stripe_account
    from
         {{ref('historical_mrr')}} silim
        left join {{ source('dbt_stripe_account_src', 'plan') }} p on silim.plan_id = p.id
    where
        mrr <> 0
       group by 2,3,5,6,"date"
    order by
        2 asc,
        3 asc
),
churn as (
    select
        customer_id,
        mrr_day,
        coalesce(
            lag(mrr) over (
                partition by customer_id
                order by
                    mrr_day asc
            ),
            0
        ) as starting_mrr,
        mrr - coalesce(
            lag(mrr) over (
                partition by customer_id
                order by
                    mrr_day asc
            ),
            0
        ) as mrr_change,
        mrr as ending_mrr,
        case
            when lead(mrr_day) over (
                partition by customer_id
                order by
                    mrr_day asc
            ) - mrr_day > plan_period_in_days + 30 then 'Churn'
            when lead(mrr_day) over (
                partition by customer_id
                order by
                    mrr_day asc
            ) is null
            and plan_period_in_days <> 365
            and date_trunc('month', mrr_day) <> date_trunc('month', current_date + interval '-1' month)::date
            then 'Churn'
            when plan_period_in_days >= 365
            and mrr_day > (mrr_day + cast(plan_period_in_days as integer) + 30)
            then 'Churn'
            when mn = 1 then case
                when date_trunc('month', current_date + interval '-1' month) :: date - date_trunc(
                    'month',
                    max(mrr_day) over (partition by customer_id)
                ) :: date > plan_period_in_days + 30 then 'Churn'
            end
        end as churn_event,
        plan_period_in_days,
        (mrr_day + interval '1' day * plan_period_in_days) :: date as next_mrr_day,
        stripe_account,
        mn
    from
        mrr_calc
    order by
        customer_id asc,
        mrr_day asc,
        churn_event desc
),
movements as (
select
    distinct customer_id,
    mrr_day,
    case
        when lag(churn_event) over (
            partition by customer_id
            order by
                mrr_day asc
        ) = 'Churn'
        and mrr_day <> lag(mrr_day) over (
            partition by customer_id
            order by
                mrr_day asc
        )
        and churn_event is null
        then 'Reactivation'
        else churn_event
    end as event_type,
    stripe_account,
    mn
from
    churn
order by
    customer_id asc,
    mrr_day asc),
final as (select 
	customer_id, 
	case
		when event_type = 'Churn' then (mrr_day+ INTERVAL '1 month')::date
		else mrr_day::date
	end as mrr_day,
	event_type,
	stripe_account,
	mn
from movements
where event_type is not null
union all
select 
	customer_id, 
	case
		when lag(event_type) over (partition by customer_id order by mrr_day asc) = 'Churn'
		and event_type = 'Churn'
		then mrr_day::date
		when event_type = 'Churn' then (mrr_day+ INTERVAL '1 month')::date
		else mrr_day::date
	end as mrr_day,
	case 
		when lag(event_type) over (partition by customer_id order by mrr_day asc) = 'Churn'
		and event_type = 'Churn'
		then 'Reactivation'
		else event_type end as event_type,
	stripe_account,
	mn
from movements
where event_type is not null)
select distinct  * 
from final