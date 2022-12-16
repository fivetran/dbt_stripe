
with spine as (

    {% if execute %}
    {% set first_date_query %}
        select  min( created_at ) as min_date from {{ ref('stripe__balance_transactions') }}
    {% endset %}
    {% set first_date = run_query(first_date_query).columns[0][0]|string %}
    
        {% if target.type == 'postgres' %}
            {% set first_date_adjust = "cast('" ~ first_date[0:10] ~ "' as date)" %}

        {% else %}
            {% set first_date_adjust = "'" ~ first_date[0:10] ~ "'" %}

        {% endif %}

    {% else %} {% set first_date_adjust = "'2009-01-01'" %}
    {% endif %}

    {% if execute %}
    {% set last_date_query %}
        select  max( created_at ) as max_date from {{ ref('stripe__balance_transactions') }}
    {% endset %}

    {% set current_date_query %}
        select current_date
    {% endset %}

    {% if run_query(current_date_query).columns[0][0]|string < run_query(last_date_query).columns[0][0]|string %}

    {% set last_date = run_query(last_date_query).columns[0][0]|string %}

    {% else %} {% set last_date = run_query(current_date_query).columns[0][0]|string %}
    {% endif %}
        
    {% if target.type == 'postgres' %}
        {% set last_date_adjust = "cast('" ~ last_date[0:10] ~ "' as date)" %}

    {% else %}
        {% set last_date_adjust = "'" ~ last_date[0:10] ~ "'" %}

    {% endif %}
    {% endif %}

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date=first_date_adjust,
        end_date=dbt.dateadd("day", 1, last_date_adjust)
        )
    }}
),

balance_transactions as (
    
    select *
    from {{ ref('stripe__balance_transactions') }}
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