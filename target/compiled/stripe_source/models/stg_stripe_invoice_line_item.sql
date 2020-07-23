

with invoice_line_item as (

    select *
    from `dbt-package-testing`.`stripe`.`invoice_line_item`

), fields as (

    select
      id as invoice_line_item_id,
      invoice_id,
      amount,
      currency,
      description,
      discountable as is_discountable,
      plan_id,
      proration,
      quantity,
      subscription_id,
      subscription_item_id,
      type,
      unique_id
    from invoice_line_item
    where id not like 'sub%' -- ids starting with 'sub' are temporary and are replaced by permanent ids starting with 'sli' 

)

select * from fields