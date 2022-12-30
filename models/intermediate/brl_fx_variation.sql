with mrr_sum_br as (
	select 
		customer_id,
		date_trunc('day', "date")::date as mrr_day,
		row_number() over (partition by customer_id, round(sum(brl_mrr)::numeric,2) order by "date" asc) as rn1,
		round(sum(mrr)::numeric,2)  as mrr,
		round(sum(brl_mrr)::numeric,2)  as brl_mrr,
		stripe_account 
	from {{ref('historical_mrr')}}
	where mrr <> 0
	and stripe_account = 'br'
	group by 1,2,stripe_account, "date"),
jumping_rule_1 as (
	select	
		*,
		row_number() over(partition by customer_id order by mrr_day desc) x,
		row_number() over(partition by customer_id, 
			case rn1 when 1 then 1 else 0 end
			order by mrr_day desc) y
		from mrr_sum_br
			),
jumping_rule_2 AS (
     SELECT *,
            ROW_NUMBER() OVER(PARTITION by customer_id,  x-y ORDER BY x ASC) z1,
            ROW_NUMBER() OVER(PARTITION BY customer_id, x-y ORDER BY x DESC) z2 
     FROM jumping_rule_1),
final as (
select 
	*,
	case rn1 when 1 then
		LAG(mrr,cast(z1 as integer),mrr) OVER(PARTITION BY customer_id, rn1 ORDER BY x) 
           ELSE LAG(mrr,cast(z1 as integer),mrr) OVER(PARTITION BY customer_id  ORDER BY x) 
           END,
    CASE rn1 WHEN 1 THEN 
           LEAD(mrr,cast(z2 as integer),mrr) OVER(PARTITION by customer_id, rn1 ORDER BY x) 
           ELSE LEAD(mrr,cast(z2 as integer),mrr) OVER(PARTITION BY customer_id ORDER BY x) 
           END
FROM jumping_rule_2)
select 
	customer_id,
	mrr_day,
	case
		when rn1 = 1 then mrr
		else "lead"
	end as mrr,
	stripe_account 	
from final
order by 1,2