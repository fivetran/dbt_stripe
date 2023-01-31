with balance_transaction_joined as (

    select *
    from {{ ref('stripe__balance_transactions') }}  

), incomplete_charges as (

    select *
    from {{ ref('int_stripe__incomplete_charges') }}  

), customer as (

    select *
    from {{ var('customer') }}  

), transactions_grouped as (

    select
      customer_id,
      source_relation,
      sum(
        case 
          when type in ('charge', 'payment') 
          then amount
          else 0 
        end) 
      as total_sales,
      sum(
        case 
          when type in ('payment_refund', 'refund') 
          then amount
          else 0 
        end) 
      as total_refunds,    
      sum(amount) as total_gross_transaction_amount,
      sum(fee) as total_fees,
      sum(net) as total_net_transaction_amount,
      sum(
        case 
          when type in ('charge', 'payment') 
          then 1
          else 0 
          end) 
      as total_sales_count, 
      sum(
        case 
          when type in ('payment_refund', 'refund') 
          then 1
          else 0 
        end) 
      as total_refund_count,   
      sum(
        case 
          when type in ('charge', 'payment') and {{ dbt.date_trunc('month', date_timezone('created_at')) }} = {{ dbt.date_trunc('month', date_timezone(dbt.current_timestamp_backcompat())) }}
          then amount 
          else 0 
        end) 
      as sales_this_month,
      sum(
        case 
          when type in ('payment_refund', 'refund') and {{ dbt.date_trunc('month', date_timezone('created_at')) }} = {{ dbt.date_trunc('month', date_timezone(dbt.current_timestamp_backcompat())) }}
          then amount 
          else 0 
        end) 
      as refunds_this_month,
      sum(
        case 
          when {{ dbt.date_trunc('month', date_timezone('created_at')) }} = {{ dbt.date_trunc('month', date_timezone(dbt.current_timestamp_backcompat())) }}
          then amount 
          else 0 
        end) 
      as gross_transaction_amount_this_month,
      sum(
        case 
          when {{ dbt.date_trunc('month', date_timezone('created_at')) }} = {{ dbt.date_trunc('month', date_timezone(dbt.current_timestamp_backcompat())) }}
          then fee 
          else 0 
        end) 
      as fees_this_month,
      sum(
        case 
          when {{ dbt.date_trunc('month', date_timezone('created_at')) }} = {{ dbt.date_trunc('month', date_timezone(dbt.current_timestamp_backcompat())) }}
          then net 
          else 0 
        end) 
      as net_transaction_amount_this_month,
      sum(
        case 
          when type in ('charge', 'payment') and {{ dbt.date_trunc('month', date_timezone('created_at')) }} = {{ dbt.date_trunc('month', date_timezone(dbt.current_timestamp_backcompat())) }}
          then 1 
          else 0 
        end) 
      as sales_count_this_month,
      sum(
        case 
          when type in ('payment_refund', 'refund') and {{ dbt.date_trunc('month', date_timezone('created_at')) }} = {{ dbt.date_trunc('month', date_timezone(dbt.current_timestamp_backcompat())) }}
          then 1 
          else 0 
        end) 
      as refund_count_this_month,
      min(
        case 
          when type in ('charge', 'payment') 
          then {{ date_timezone('created_at') }}
          else null 
        end) 
      as first_sale_date,
      max(
        case 
          when type in ('charge', 'payment') 
          then {{ date_timezone('created_at') }}
          else null 
        end) 
      as most_recent_sale_date
    from balance_transaction_joined
    where type in ('payment', 'charge', 'payment_refund', 'refund')
    group by 1,2

), failed_charges_by_customer as (

    select
      customer_id,
      source_relation,
      count(*) as total_failed_charge_count,
      sum(amount) as total_failed_charge_amount,
      sum(
        case 
          when {{ dbt.date_trunc('month', date_timezone('created_at')) }} = {{ dbt.date_trunc('month', date_timezone(dbt.current_timestamp_backcompat())) }}
          then 1
          else 0 
        end) 
      as failed_charge_count_this_month,
      sum(
        case 
          when {{ dbt.date_trunc('month', date_timezone('created_at')) }} = {{ dbt.date_trunc('month', date_timezone(dbt.current_timestamp_backcompat())) }}
          then amount
          else 0 
        end) 
      as failed_charge_amount_this_month
    from incomplete_charges
    group by 1,2

), transactions_not_associated_with_customer as (

    select
      'No Customer ID' as customer_id,
      'No Associated Customer' as customer_description,
      customer.created_at as customer_created_at,
      customer.currency as customer_currency,
      {{ dbt_utils.star(from=ref('stg_stripe__customer'), relation_alias='customer', except=['customer_id','description','created_at','currency','metadata','source_relation']) }},
      coalesce(transactions_grouped.total_sales/100.0, 0) as total_sales,
      coalesce(transactions_grouped.total_refunds/100.0, 0) as total_refunds,
      coalesce(transactions_grouped.total_gross_transaction_amount/100.0, 0) as total_gross_transaction_amount,
      coalesce(transactions_grouped.total_fees/100.0, 0) as total_fees,
      coalesce(transactions_grouped.total_net_transaction_amount/100.0, 0) as total_net_transaction_amount,
      coalesce(transactions_grouped.total_sales_count, 0) as total_sales_count,
      coalesce(transactions_grouped.total_refund_count, 0) as total_refund_count,    
      coalesce(transactions_grouped.sales_this_month/100.0, 0) as sales_this_month,
      coalesce(transactions_grouped.refunds_this_month/100.0, 0) as refunds_this_month,
      coalesce(transactions_grouped.gross_transaction_amount_this_month/100.0, 0) as gross_transaction_amount_this_month,
      coalesce(transactions_grouped.fees_this_month/100.0, 0) as fees_this_month,
      coalesce(transactions_grouped.net_transaction_amount_this_month/100.0, 0) as net_transaction_amount_this_month,
      coalesce(transactions_grouped.sales_count_this_month, 0) as sales_count_this_month,
      coalesce(transactions_grouped.refund_count_this_month, 0) as refund_count_this_month,
      transactions_grouped.first_sale_date,
      transactions_grouped.most_recent_sale_date,
      0 as total_failed_charge_count,
      0 as total_failed_charge_amount,
      0 as failed_charge_count_this_month,
      0 as failed_charge_amount_this_month,
      transactions_grouped.source_relation

    from transactions_grouped
    left join customer 
        on transactions_grouped.customer_id = customer.customer_id
        and transactions_grouped.source_relation = customer.source_relation
    where customer.customer_id is null and customer.description is null


), customer_transactions_overview as (

    select
      customer.customer_id,
      customer.description as customer_description,
      customer.created_at as customer_created_at,
      customer.currency as customer_currency,
      {{ dbt_utils.star(from=ref('stg_stripe__customer'), relation_alias='customer', except=['customer_id','description','created_at','currency','metadata','source_relation']) }},
      coalesce(transactions_grouped.total_sales/100.0, 0) as total_sales,
      coalesce(transactions_grouped.total_refunds/100.0, 0) as total_refunds,
      coalesce(transactions_grouped.total_gross_transaction_amount/100.0, 0) as total_gross_transaction_amount,
      coalesce(transactions_grouped.total_fees/100.0, 0) as total_fees,
      coalesce(transactions_grouped.total_net_transaction_amount/100.0, 0) as total_net_transaction_amount,
      coalesce(transactions_grouped.total_sales_count, 0) as total_sales_count,
      coalesce(transactions_grouped.total_refund_count, 0) as total_refund_count,    
      coalesce(transactions_grouped.sales_this_month/100.0, 0) as sales_this_month,
      coalesce(transactions_grouped.refunds_this_month/100.0, 0) as refunds_this_month,
      coalesce(transactions_grouped.gross_transaction_amount_this_month/100.0, 0) as gross_transaction_amount_this_month,
      coalesce(transactions_grouped.fees_this_month/100.0, 0) as fees_this_month,
      coalesce(transactions_grouped.net_transaction_amount_this_month/100.0, 0) as net_transaction_amount_this_month,
      coalesce(transactions_grouped.sales_count_this_month, 0) as sales_count_this_month,
      coalesce(transactions_grouped.refund_count_this_month, 0) as refund_count_this_month,
      transactions_grouped.first_sale_date,
      transactions_grouped.most_recent_sale_date,
      coalesce(failed_charges_by_customer.total_failed_charge_count, 0) as total_failed_charge_count,
      coalesce(failed_charges_by_customer.total_failed_charge_amount/100, 0) as total_failed_charge_amount,
      coalesce(failed_charges_by_customer.failed_charge_count_this_month, 0) as failed_charge_count_this_month,
      coalesce(failed_charges_by_customer.failed_charge_amount_this_month/100, 0) as failed_charge_amount_this_month,
      customer.source_relation
      
    from customer
    left join transactions_grouped
        on customer.customer_id = transactions_grouped.customer_id
        and customer.source_relation = transactions_grouped.source_relation
    left join failed_charges_by_customer 
        on customer.customer_id = failed_charges_by_customer.customer_id
        and customer.source_relation = failed_charges_by_customer.source_relation
)

select *
from transactions_not_associated_with_customer
union all 
select * 
from customer_transactions_overview