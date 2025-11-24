{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- this test ensures the subscription_item_mrr_report end model matches the prior version
-- aggregated on the subscription_month, subscription_year, and source_relation grain
-- the below iterates through the prod and dev names to reduce redundancy of logic
with
{% for prod_or_dev in ('prod', 'dev') %}
    {% set cols = adapter.get_columns_in_relation(ref('stripe__subscription_item_mrr_report')) %}
    {{ prod_or_dev }} as (
        select
            subscription_month,
            subscription_year,
            source_relation
            {% for col in cols if col.name not in ["subscription_item_id", "subscription_id", "customer_id", "product_id", "subscription_status", "currency", "subscription_month", "subscription_year", "source_relation", "item_month_number", "mrr_type"] %}
                , floor(sum({{ col.name }})) as summed_{{ col.name }} -- floor and sum is to keep consistency between dev and prod aggs
            {% endfor %}
        from {{ target.schema }}_stripe_{{ prod_or_dev }}.stripe__subscription_item_mrr_report
        group by 1,2,3
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
