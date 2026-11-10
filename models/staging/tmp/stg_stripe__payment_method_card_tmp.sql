{{ config(enabled=var('stripe__using_payment_method', True)) }}

{{ stripe.resolve_source_columns(table_name='payment_method_card', staging_columns=stripe.get_payment_method_card_columns()) }}
