{{ config(enabled=var('stripe__using_transfers', True)) }}

{{ stripe.resolve_source_columns(table_name='transfer', staging_columns=stripe.get_transfer_columns()) }}
