select distinct 
    ili.invoice_id,
    ili.unique_id item_id,
    ili.subscription_item_id,
    p2."name" as product_name,
    p2.product_class,
    d.location as location,
    coalesce(d.region, pr.region) as region,
    d.device_count,
    ili.stripe_account
from
    {{source('dbt_stripe_account_src', 'invoice_line_item')}} ili
        left join {{ref('netbox_device')}} d on d.subscription_item_id = ili.subscription_item_id and d.subscription_item_id is not null
        left join {{source('dbt_stripe_account_src', 'price')}} p on ili.price_id = p.id
        left join {{ref('stripe_product')}} p2 on p.product_id = p2.id
        left join {{ref('stripe_price_region')}} pr on pr.id = ili.price_id