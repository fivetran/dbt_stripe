{{ config(
    tags="fivetran_validations",
    enabled=var('stripe__standardized_billing_model_enabled', True)
        and var('stripe__using_invoices', True)
) }}

-- Check the published unit prices against known fractional, negative, and zero-quantity examples.
with expected as (
    select
        invoice_line_item.invoice_line_item_id,
        invoice_line_item.source_relation,
        cast(
            {% if var('stripe__convert_values', false) %}
            unit_amount_expected.unit_amount / 100.0
            {% else %}
            unit_amount_expected.unit_amount
            {% endif %}
            as {{ dbt.type_numeric() }}
        ) as unit_amount
    from {{ ref('stg_stripe__invoice_line_item') }} as invoice_line_item
    join {{ ref('line_item_unit_amount_expected') }} as unit_amount_expected
        on invoice_line_item.invoice_line_item_id = unit_amount_expected.line_item_id
), actual as (
    select *
    from {{ ref('stripe__line_item_enhanced') }}
    where record_type = 'line_item'
)

select
    expected.invoice_line_item_id,
    expected.source_relation,
    expected.unit_amount as expected_unit_amount,
    count(actual.line_item_id) as actual_row_count,
    min(actual.unit_amount) as actual_unit_amount
from expected
left join actual
    on expected.invoice_line_item_id = actual.line_item_id
    and expected.source_relation = actual.source_relation
group by 1, 2, 3
having count(actual.line_item_id) != 1
    or min(actual.unit_amount) is null
    or min(actual.unit_amount) != expected.unit_amount
