with customer_discount as (
    select * from {{ var("customer_discount") }}
),
subscription_discount as (
    select * from {{ var("subscription_discount") }}
),
coupon as (
    select * from {{ var("coupon") }}
),
percent_discount as ( --manually including products with percent discount
        SELECT  sh.customer_id,
        si.subscription_id,
        c.id as coupon_id,
        (si.quantity * p.unit_amount) as amount,
        CASE WHEN si.plan_id in ('price_1LOPdtLpWuMxVFxQCUJtRMMC','price_1L588HLpWuMxVFxQfcsqphDj','price_1JpTJdLpWuMxVFxQMwN8msM9',
        'price_1JDCRZLpWuMxVFxQibdl7icI','price_1JDCOTLpWuMxVFxQtyhUTfQ9','price_1JDBlpLpWuMxVFxQDG1bUiQM','price_1IzmO6LpWuMxVFxQqsYT2AjJ',
        'price_1IvrDFLpWuMxVFxQsG6zHJxH') and sh.customer_id in ('cus_K6uy58bqmGY6g5', 'cus_KvDyLIIG3dablw', 
        'cus_JosSmyQjnn4z42', 'cus_JRAn4goXgWi8Y2', 'cus_JlgKKwOhoOzmLX', 'cus_KYmetKpcVBLju8') THEN ((si.quantity * p.unit_amount) * (c.percent_off/100))
        END as amount_discount,
        c.percent_off

        FROM  {{ var('subscription_item') }} si
            left join subscription_discount sd using(subscription_id)
            left join coupon c on sd.coupon_id = c.id
            left join {{ var('price') }} p on p.id = si.plan_id
            left join {{source('dbt_stripe_account_src', 'subscription_history')}} sh on si.subscription_id = sh.id and sh._fivetran_active = True
        where sh.customer_id in ('cus_K6uy58bqmGY6g5', 'cus_KvDyLIIG3dablw', 'cus_JosSmyQjnn4z42', 'cus_JRAn4goXgWi8Y2', 
        'cus_JlgKKwOhoOzmLX', 'cus_KYmetKpcVBLju8')),
percent_discount_br as ( --manually including products with percent discount
        SELECT  sh.customer_id,
        si.subscription_id,
        c.id as coupon_id,
        (si.quantity * p.unit_amount) as amount,
        CASE WHEN si.plan_id in ('price_1LPTHtJfthNLcfkY7m3sqL8z', 'price_1LPSchJfthNLcfkYcv1l39CE', 'price_1JpTIcJfthNLcfkY1G1lox2o', 
        'price_1JDBoJJfthNLcfkYgxTd9aKk', 'price_1IzmPkJfthNLcfkYvfdjsOet', 'price_1Iw67SJfthNLcfkYwX3N8U0j', 'price_1Iw66vJfthNLcfkYcLKkZL9A', 
        'price_1Iw66aJfthNLcfkYwubMfFAf') and sh.customer_id in ('cus_K9wVZNk1alpUA5') THEN ((si.quantity * p.unit_amount) * (c.percent_off/100))
        END as amount_discount,
        c.percent_off

FROM  {{ var('subscription_item') }} si
            left join subscription_discount sd using(subscription_id)
            left join coupon c on sd.coupon_id = c.id
            left join {{ var('price') }} p on p.id = si.plan_id
            left join {{source('dbt_stripe_account_src', 'subscription_history')}} sh on si.subscription_id = sh.id and sh._fivetran_active = True

where sh.customer_id in ('cus_K9wVZNk1alpUA5')),
subscription_percent_discount as ( --manually including subscriptions with percent discount
        SELECT  sh.customer_id,
        si.subscription_id,
        c.id as coupon_id,
        (si.quantity * p.unit_amount) as amount,
        CASE WHEN si.subscription_id in ('sub_1L3U5HLpWuMxVFxQZzQyemiW', 'sub_1LAeagLpWuMxVFxQysPmXxs1', 'sub_1K8raJLpWuMxVFxQqPp36E0V') 
        THEN ((si.quantity * p.unit_amount) * (c.percent_off/100))
        END as amount_discount,
        c.percent_off

FROM  {{ var('subscription_item') }} si
  left join subscription_discount sd using(subscription_id)
  left join coupon c on sd.coupon_id = c.id
  left join {{ var('price') }} p on p.id = si.plan_id
  left join {{source('dbt_stripe_account_src', 'subscription_history')}} sh on si.subscription_id = sh.id and sh._fivetran_active = True
where si.subscription_id in ('sub_1L3U5HLpWuMxVFxQZzQyemiW', 'sub_1LAeagLpWuMxVFxQysPmXxs1', 'sub_1K8raJLpWuMxVFxQqPp36E0V')),
subscription_percent_discount_br as ( --manually including products with percent discount
        SELECT  sh.customer_id,
        si.subscription_id,
        c.id as coupon_id,
        (si.quantity * p.unit_amount) as amount,
        CASE WHEN si.subscription_id in ('sub_K4lfA8dEpFj3EF') 
        THEN ((si.quantity * p.unit_amount) * (c.percent_off/100))
        END as amount_discount,
        c.percent_off
FROM  {{ var('subscription_item') }} si
  left join subscription_discount sd using(subscription_id)
  left join coupon c on sd.coupon_id = c.id
  left join {{ var('price') }} p on p.id = si.plan_id
  left join {{source('dbt_stripe_account_src', 'subscription_history')}} sh on si.subscription_id = sh.id and sh._fivetran_active = True
where si.subscription_id in ('sub_K4lfA8dEpFj3EF') ),
laine_referral_discount as ( --manually including products with percent discount
    SELECT  sh.customer_id,
        si.subscription_id,
        c.id as coupon_id,
        (si.quantity * p.unit_amount) as amount,
        CASE WHEN si.plan_id in ('price_1LMsKKLpWuMxVFxQssW2Publ','price_1LMsJ0LpWuMxVFxQyzRuiXcE',
        'price_1LMs2MLpWuMxVFxQjCAdldaN','price_1LLWZiLpWuMxVFxQIZ4xsg6h','price_1LLWBNLpWuMxVFxQf66uTLA7',
        'price_1LD7kXLpWuMxVFxQ6bddLwjp','price_1LD7kDLpWuMxVFxQaCZHEGLo','price_1LD7fPLpWuMxVFxQquGS2SrV',
        'price_1L6NzALpWuMxVFxQBqmjn6Yy','price_1L3LPgLpWuMxVFxQKumH23ND','price_1L2abqLpWuMxVFxQUbSGqmIU',
        'price_1KzhRuLpWuMxVFxQzRYHIONs','price_1KwX8kLpWuMxVFxQiK6ELbGK','price_1KuyKyLpWuMxVFxQHxZw7uaK',
        'price_1KrNZwLpWuMxVFxQOsdWz8Ld','price_1KoRiSLpWuMxVFxQXTvwSmDL','price_1KoRiFLpWuMxVFxQ1Bx3XUIj',
        'price_1KoRi2LpWuMxVFxQ0b2bSkgm','price_1KoRhnLpWuMxVFxQVh64T78F','price_1KoRhWLpWuMxVFxQfX8Pm06H',
        'price_1KoRgZLpWuMxVFxQg0X7jeGw','price_1KoC2GLpWuMxVFxQjodo0LN2','price_1KoA7pLpWuMxVFxQxGRuMHuY',
        'price_1KoA7RLpWuMxVFxQ5n7iTf0l') and si.subscription_id in ('sub_1LIgUDLpWuMxVFxQ7QxPIldR') THEN ((si.quantity * p.unit_amount) * (c.percent_off/100))
        END as amount_discount,
        c.percent_off

FROM  {{ var('subscription_item') }} si
  left join subscription_discount sd using(subscription_id)
  left join coupon c on sd.coupon_id = c.id
  left join {{ var('price') }} p on p.id = si.plan_id
  left join {{source('dbt_stripe_account_src', 'subscription_history')}} sh on si.subscription_id = sh.id and sh._fivetran_active = True
where si.subscription_id in ('sub_1LIgUDLpWuMxVFxQ7QxPIldR'))

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
    inner join coupon
        on subscription_discount.coupon_id = coupon.id
    where 
        amount_off > 0 and
        is_deleted = false and 
        valid = true 

    union

    SELECT coupon_id, subscription_id, sum(amount_discount) as amount_off
    from percent_discount
    where amount_discount > 0
    group by 1,2

    union

    SELECT coupon_id, subscription_id, sum(amount_discount) as amount_off
    from percent_discount_br
    where amount_discount > 0
    group by 1,2

    union

    SELECT coupon_id, subscription_id, sum(amount_discount) as amount_off
    from subscription_percent_discount
    where amount_discount > 0
    group by 1,2

    union

    SELECT coupon_id, subscription_id, sum(amount_discount) as amount_off
    from subscription_percent_discount_br
    where amount_discount > 0
    group by 1,2

    union

    SELECT coupon_id, subscription_id, sum(amount_discount) as amount_off
    from laine_referral_discount
    where amount_discount > 0
    group by 1,2


) as subscription_coupons
group by subscription_id