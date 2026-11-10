{{ config(enabled=var('stripe__using_subscriptions', True)) }}

{%- set price_or_plan = 'price' if var('stripe__using_price', true) else 'plan' -%}

{{ stripe.resolve_source_columns(table_name=price_or_plan, staging_columns=stripe.get_price_plan_columns()) }}
