select distinct 
    price.id,
    nickname,
    case
        when lower(nickname) ilike '%brazil%' then 'Brazil'
        when lower(nickname) ilike '%australia%' then 'Australia'
        when lower(nickname) ilike '%japan%' then 'Japan'
        when lower(nickname) ilike '%united-states%' then 'United States'
        when lower(nickname) ilike '%united states%' then 'United States'
        when lower(nickname) ilike '%argentina%' then 'Argentina'
        when lower(nickname) ilike '%chile%' then 'Chile'
        when lower(nickname) ilike '%mexico%' then 'Mexico'
        when lower(nickname) ilike '%new york%' then 'United States'
        when lower(nickname) ilike '%united-kingdom%' then 'United Kingdom'
        when lower(nickname) ilike '%colombia%' then 'Colombia'
        when lower(nickname) ilike '%USA%' then 'United States'
        when lower(nickname) ilike '%us%' and p.product_class  = 'Bandwidth' then 'United States'
        end as region,
    p.product_class
from
    {{source('dbt_stripe_account_src', 'price')}} price
        left join {{ref('stripe_product')}} p on p.id = price.product_id