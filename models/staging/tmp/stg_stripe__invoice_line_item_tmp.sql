{{ config(enabled=var('stripe__using_invoices', True)) }}

{{ stripe.resolve_source_columns(table_name='invoice_line_item', staging_columns=stripe.get_invoice_line_item_columns()) }}
