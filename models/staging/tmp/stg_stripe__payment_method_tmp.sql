{{ config(enabled=var('stripe__using_payment_method', True)) }}

{{ stripe.resolve_source_columns(table_name='payment_method', staging_columns=stripe.get_payment_method_columns()) }}
