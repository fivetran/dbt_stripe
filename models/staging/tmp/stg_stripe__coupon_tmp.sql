{{ config(enabled=var('stripe__using_coupons', True)) }}

{{ stripe.resolve_source_columns(table_name='coupon', staging_columns=stripe.get_coupon_columns()) }}
