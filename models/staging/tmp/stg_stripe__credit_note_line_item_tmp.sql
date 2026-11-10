{{ config(enabled=var('stripe__using_credit_notes', False)) }}

{{ stripe.resolve_source_columns(table_name='credit_note_line_item', staging_columns=stripe.get_credit_note_line_item_columns()) }}
