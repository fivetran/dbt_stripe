{{ config(enabled=var('stripe__using_credit_notes', False)) }}

with base as (

    select * 
    from {{ ref('stg_stripe__credit_note_line_item_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__credit_note_line_item_tmp')),
                staging_columns=get_credit_note_line_item_columns()
            )
        }}

        {{ stripe.apply_source_relation() }}

    from base
),

final as (
    
    select 
        id as credit_note_line_item_id,
        credit_note_id,
        {{ stripe.convert_values('amount', alias='credit_note_line_item_amount') }},
        {{ stripe.convert_values('discount_amount', alias='credit_note_line_item_discount_amount') }},
        description as credit_note_line_item_description,
        quantity,
        type as credit_note_line_item_type,
        unit_amount as credit_note_line_item_unit_amount,
        livemode,
        source_relation

    from fields
    {{ livemode_predicate() }}
)

select * 
from final
