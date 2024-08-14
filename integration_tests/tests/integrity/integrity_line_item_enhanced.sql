{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with staging_model as (
    select 
        invoice_id as header_id,
        count(*) as stg_line_item_count,
    from {{ ref('stg_stripe__invoice_line_item') }}
    group by 1
),

end_model as (
    select 
        header_id,
        count(*) as end_model_count
    from {{ ref('stripe__line_item_enhanced') }}
    group by 1
),

final as (
    select 
        end_model.header_id as end_header_id,
        staging_model.header_id as staging_header_id,
        end_model.end_model_count as end_model_row_count,
        (staging_model.stg_line_item_count + 1) as stg_model_row_count
    from staging_model
    full outer join end_model
        on end_model.header_id = staging_model.header_id
)

select *
from final
where end_model_row_count > stg_model_row_count -- At this moment we are most concerned about fanout. We will need to add significant logic to account for invoices that don't receive a header record. Therefore, to avoid this we can relying on the fact that no fanouts (end model has a greater count than staging) are occurring from this integrity test is sufficient.
    or end_header_id is null or staging_header_id is null