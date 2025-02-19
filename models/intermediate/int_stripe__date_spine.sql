-- depends_on: {{ ref('stripe__balance_transactions') }}
with spine as (

    {% if execute and flags.WHICH in ('run', 'build') %}

    {%- set first_date_query %}
        select coalesce(
            min(cast(balance_transaction_created_at as date)), 
            cast({{ dbt.dateadd("month", -1, "current_date") }} as date)
        ) as min_date
        from {{ ref('stripe__balance_transactions') }}
    {% endset -%}

    {%- set first_date_pre = dbt_utils.get_single_value(first_date_query) %}
    {% set first_date = "cast('" ~ first_date_pre ~ "' as date)" %}

    {% set last_date_query %}
        select coalesce(
            greatest(max(cast(balance_transaction_created_at as date)), cast(current_date as date)),
            cast(current_date as date)
        ) as max_date
        from {{ ref('stripe__balance_transactions') }}
    {% endset %}

    {% set last_date_pre = dbt_utils.get_single_value(last_date_query) %}
    {% set last_date = "cast('" ~ last_date_pre ~ "' as date)" %}

    {% else %}

    {% if target.type == 'redshift' %}
        {% set first_date = dbt.dateadd("month", -1, "current_date") %}
        {% set last_date = dbt.current_timestamp_backcompat() %}
    {% else %}
        {% set first_date = dbt.dateadd("month", -1, "current_date") %}
        {% set last_date = dbt.current_timestamp_backcompat() %}
    {% endif %}

    {% endif %}
    
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date=first_date,
        end_date=dbt.dateadd("day", 1, last_date)
    ) }}

),

account as (
    select *
    from {{ var('account') }}
),

date_spine as (
    select
        cast({{ dbt.date_trunc("day", "date_day") }} as date) as date_day, 
        cast({{ dbt.date_trunc("week", "date_day") }} as date) as date_week, 
        cast({{ dbt.date_trunc("month", "date_day") }} as date) as date_month,
        cast({{ dbt.date_trunc("year", "date_day") }} as date) as date_year,  
        row_number() over (order by cast({{ dbt.date_trunc("day", "date_day") }} as date)) as date_index
    from spine
),

final as (
    select distinct
        account.account_id,
        account.source_relation,
        date_spine.date_day,
        date_spine.date_week,
        date_spine.date_month,
        date_spine.date_year,
        date_spine.date_index
    from account 
    cross join date_spine
)

select * 
from final
