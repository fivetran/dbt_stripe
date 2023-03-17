{% snapshot current_mrr_snapshot %}

{{
    config(
      target_schema='dbt_data_marts',
      strategy='check',
      unique_key='customer_id',

      
      check_cols=['mrr'],
      invalidate_hard_deletes=True,
    )
}}

    select customer_id, name, sum(mrr) as mrr from {{ref('current_mrr')}} 
    where customer_id NOT IN ('cus_MVjwgFklliUF9p','cus_J8IS1IGMxzZLzR')
    group by 1,2
    order by 1

{% endsnapshot %}