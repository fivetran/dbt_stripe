with mrr_calc as (
    select
        row_number() over(
            partition by customer_id
            order by
                estimated_service_start desc
        ) as mn,
        silim.customer_id,
        date_trunc('day', silim.estimated_service_start) :: date as mrr_day,
        mrr as mrr,
        case
            p."interval"
            when 'week' then p.interval_count * 7
            when 'month' then p.interval_count * 30
            when 'year' then p.interval_count * 365
        end as plan_period_in_days,
        silim.stripe_account
    from
        {{ref('stripe__invoice_line_items_mrr')}}  silim
        left join {{ source('dbt_stripe_account_src', 'plan') }} p on silim.plan_id = p.id
    where
        mrr <> 0
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
            ) - mrr_day > plan_period_in_days + 30 then 'churn'
            when lead(mrr_day) over (
                partition by customer_id
                order by
                    mrr_day asc
            ) = null
            and date_trunc('month', mrr_day) <> '2022-08-01' then 'churn'
            when mn = 1 then case
                when date_trunc('month', current_date + interval '-1' month) :: date - date_trunc(
                    'month',
                    max(mrr_day) over (partition by customer_id)
                ) :: date > plan_period_in_days + 30 then 'churn'
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
)
select
    distinct customer_id,
    mrr_day,
    case
        when lag(churn_event) over (
            partition by customer_id
            order by
                mrr_day asc
        ) = 'churn'
        and mrr_day <> lag(mrr_day) over (
            partition by customer_id
            order by
                mrr_day asc
        ) then 'Reactivation'
        else churn_event
    end as event_type,
    stripe_account
from
    churn
order by
    customer_id asc,
    mrr_day asc