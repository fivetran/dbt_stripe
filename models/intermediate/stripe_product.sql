select
    p.id,
    p.name,
    p.created,
    pc."name" as product_class
from
    {{source('dbt_stripe_account_src', 'product')}} p
        left join {{source('dbt_stripe_account_src', 'product_classes')}} pc on p.product_class = pc.id