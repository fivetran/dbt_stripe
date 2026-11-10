{{ config(enabled=var('stripe__using_subscriptions', True)) }}

{%- set history_or_subscription = 'subscription_history' if var('stripe__using_subscription_history', stripe.source_config_has_table('subscription_history')) else 'subscription' -%}

{{ stripe.resolve_source_columns(table_name=history_or_subscription, staging_columns=stripe.get_subscription_columns()) }}
