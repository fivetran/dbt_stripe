{{ config(enabled=var('stripe__using_subscriptions', True)) }}

{{ stripe.resolve_source_columns(table_name='product', staging_columns=stripe.get_product_columns()) }}
