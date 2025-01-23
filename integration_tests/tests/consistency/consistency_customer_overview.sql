{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- this test ensures the customer_overview end model matches the prior version by comparing the aggregated fields
-- the below iterates through the prod and dev names to reduce redundancy of logic
with
{% for prod_or_dev in ('prod', 'dev') %}
    {% set cols = [
        'total_sales',
        'total_refunds',
        'total_gross_transaction_amount',
        'total_fees',
        'total_net_transaction_amount',
        'total_sales_count',
        'total_refund_count',
        'sales_this_month',
        'refunds_this_month',
        'gross_transaction_amount_this_month',
        'fees_this_month',
        'net_transaction_amount_this_month',
        'sales_count_this_month',
        'refund_count_this_month',
        'total_failed_charge_count',
        'total_failed_charge_amount',
        'failed_charge_count_this_month',
        'failed_charge_amount_this_month'
    ] %}

    {{ prod_or_dev }} as (
        select
            {% for col in cols %}
                {% if not loop.first %}, {% endif %}
                floor(sum({{ col }})) as summed_{{ col }} -- floor and sum is to keep consistency between dev and prod aggs
            {% endfor %}
        from {{ target.schema }}_stripe_{{ prod_or_dev }}.stripe__customer_overview
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