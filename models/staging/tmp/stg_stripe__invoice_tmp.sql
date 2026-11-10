{{ config(enabled=var('stripe__using_invoices', True)) }}

{{ stripe.resolve_source_columns(table_name='invoice', staging_columns=stripe.get_invoice_columns()) }}
