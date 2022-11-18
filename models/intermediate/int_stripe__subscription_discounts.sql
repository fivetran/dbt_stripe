with customer_discount as (
    select * from {{ var("customer_discount") }}
),
subscription_discount as (
    select * from {{ var("subscription_discount") }}
),
coupon as (
    select id,
			to_timestamp(created)::date,
            amount_off,
			percent_off,
		 	trim('[]" ' from json_extract_path_text(applies_to, 'products')) as applies_to,
		 	stripe_account from {{ var("coupon") }}
),
price as (
	select 
		p.id as price_id,
		p.unit_amount,
		p.unit_amount_decimal,
		c.id as coupon_id,
		c.percent_off,
		c.applies_to,
		p.stripe_account
	from dbt_stripe_account_src.price p 
		join coupon c on p.product_id = c.applies_to and c.stripe_account = p.stripe_account
	where c.applies_to is not null
	and c.percent_off is not null
	order by 1),
products_percent_discount as (
    select distinct 
        si.subscription_id,
        p.price_id,
        p.coupon_id,
        (si.quantity * p.unit_amount) as amount,
        ((si.quantity * p.unit_amount) * (p.percent_off/100)) as amount_discount,
        p.percent_off,
        si.stripe_account 
    from dbt_stripe_account_src.subscription_item si 
        left join dbt_stripe_account_src.subscription_discount sd using(subscription_id)
        left join price p on p.price_id = si.plan_id and p.coupon_id = sd.coupon_id
    where p.coupon_id is not null
    order by 1),
subscription_percent_discount as (
    select
        si.subscription_id,
        c.id as coupon_id,
        (si.quantity * p.unit_amount) as amount,
		((si.quantity * p.unit_amount) * (c.percent_off/100)) as amount_discount,
        c.percent_off
    from dbt_stripe_account_src.subscription_item si 
        left join dbt_stripe_account_src.subscription_discount sd using(subscription_id)
        left join coupon c on sd.coupon_id = c.id
        left join dbt_stripe_account_src.price p on p.id = si.plan_id
    where c.id is not null
        and c.percent_off is not null
        and c.applies_to is null
    order by 1
)

select 
    subscription_coupons.subscription_id, 
    sum(amount_off) as discounts
from 
(
    select  
        coupon_id,
        subscription_id,
        amount_off
    from customer_discount
    inner join coupon
        on customer_discount.coupon_id = coupon.id
    where 
        amount_off > 0

    union

    select  
        coupon_id,
        subscription_id,
        amount_off
    from subscription_discount
    inner join coupon
        on subscription_discount.coupon_id = coupon.id
    where 
        amount_off > 0

    union

    SELECT coupon_id, subscription_id, sum(amount_discount) as amount_off
    from products_percent_discount
    where amount_discount > 0
    group by 1,2

    union

    SELECT coupon_id, subscription_id, sum(amount_discount) as amount_off
    from subscription_percent_discount
    where amount_discount > 0
    group by 1,2


) as subscription_coupons
group by subscription_id