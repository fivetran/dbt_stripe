{{ config(enabled=var('stripe__using_subscription_discounts', True)) }}

{{ stripe.resolve_source_columns(table_name='subscription_discount', staging_columns=stripe.get_subscription_discount_columns()) }}
