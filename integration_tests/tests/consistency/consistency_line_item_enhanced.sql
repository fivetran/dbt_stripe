{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select *
    except(fee_amount, refund_amount, transaction_type) --remove before merge
    from {{ target.schema }}_stripe_prod.stripe__line_item_enhanced
),

dev as (
    select *
    except(fee_amount, refund_amount, transaction_type) --remove before merge
    from {{ target.schema }}_stripe_dev.stripe__line_item_enhanced
),

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