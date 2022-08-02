with customer_discount as (
    select * from {{ var("customer_discount") }}
),
subscription_discount as (
    select * from {{ var("subscription_discount") }}
),
coupon as (
    select * from {{ var("coupon") }}
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
        amount_off > 0 and
        is_deleted = false and 
        valid = true 

    union

    select  
        coupon_id,
        subscription_id,
        amount_off
    from subscription_discount
    inner join ft_stripe_us.coupon
        on subscription_discount.coupon_id = coupon.id
    where 
        amount_off > 0 and
        is_deleted = false and 
        valid = true 
) as subscription_coupons
group by subscription_id