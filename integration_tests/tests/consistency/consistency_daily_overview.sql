{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- this test ensures the daily_overview end model matches the prior version
-- and is aggregated on the date_index grain since the rollings totals will cause variation at the account_id grain
-- the below iterates through the prod and dev names to reduce redudancy of logic
with
{% for prod_or_dev in ('prod', 'dev') %}
    {% set cols = adapter.get_columns_in_relation(ref('stripe__daily_overview')) %}
    {{ prod_or_dev }} as (
        select
            date_index,
            source_relation
            {% for col in cols if col.name not in ["account_id", "account_daily_id", "date_day", "date_week", "date_month", "date_year", "date_index", "source_relation"] %}
                , floor(sum({{ col.name }})) as summed_{{ col.name }} -- floor and sum is to keep consistency between dev and prod aggs
            {% endfor %}
        from {{ target.schema }}_stripe_{{ prod_or_dev }}.stripe__daily_overview
        group by 1,2 -- need to group to remove randomization stemming from rolling totals
    ),
{% endfor %} 

prod_not_in_dev as (
    -- rows from prod not found in dev
    select * from prod
    except distinct
    select * from dev
),

dev_not_in_prod as (
    -- rows from dev not found in prod
    select * from dev
    except distinct
    select * from prod
),

final as (
    select
        *,
        'from prod' as source
    from prod_not_in_dev

    union all -- union since we only care if rows are produced

    select
        *,
        'from dev' as source
    from dev_not_in_prod
)

select *
from final