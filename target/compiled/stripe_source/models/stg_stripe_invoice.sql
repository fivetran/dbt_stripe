

with invoice as (

    select *
    from `dbt-package-testing`.`stripe`.`invoice`

), fields as (

    select
      id as invoice_id,
      amount_due,
      amount_paid,
      amount_remaining,
      attempt_count,
      auto_advance,
      billing_reason,
      charge_id,
      created as created_at,
      currency,
      customer_id,
      description,
      due_date,
      number,
      paid as is_paid,
      receipt_number,
      status,
      subtotal,
      tax,
      tax_percent,
      total
    from invoice
    where not coalesce(is_deleted, false)

)

select * from fields