{{ config(enabled=var('stripe__using_credit_notes', False)) }}

with fields as (

    select *
    from {{ ref('stg_stripe__credit_note_tmp') }}
),

final as (
    select 
        id as credit_note_id,
        {{ stripe.convert_values('amount', alias='credit_note_amount') }},
        {{ stripe.convert_values('discount_amount', alias='credit_note_discount_amount') }},
        {{ stripe.convert_values('subtotal', alias='credit_note_subtotal') }},
        {{ stripe.convert_values('total', alias='credit_note_total') }},
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        currency as credit_note_currency,
        memo,
        metadata,
        number as credit_note_number,
        pdf,
        reason as credit_note_reason,
        status as credit_note_status,
        type as credit_note_type,
        cast(voided_at as {{ dbt.type_timestamp() }}) as voided_at,
        customer_balance_transaction,
        invoice_id,
        refund_id,
        source_relation

    from fields
    {{ livemode_predicate() }}
)

select * 
from final
