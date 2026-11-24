{{ config(enabled=var('stripe__using_credit_notes', False)) }}

with fields as (

    {{ stripe.resolve_source_columns(table_name='credit_note_line_item', staging_columns=stripe.get_credit_note_line_item_columns()) }}
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
