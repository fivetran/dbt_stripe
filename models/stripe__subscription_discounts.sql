with customer_discount as (
    select * from {{ var("customer_discount") }}
),
subscription_discount as (
    select * from {{ var("subscription_discount") }}
),
coupon as (
    select * from {{ var("coupon") }}
)

SELECT  
    customer_id,
    "start",
    "end",
    coupon_id,
    subscription_id,
    amount_off
FROM customer_discount
inner join coupon
    on customer_discount.coupon_id = coupon.id
where 
    amount_off > 0 and
    is_deleted = false and 
    valid = true

union

SELECT  
    customer_id,
    "start",
    "end",
    coupon_id,
    subscription_id,
    amount_off
FROM subscription_discount
inner join ft_stripe_us.coupon
    on subscription_discount.coupon_id = coupon.id
where 
    amount_off > 0 and
    is_deleted = false and 
    valid = true 
