{{ config(enabled=var('stripe__using_subscriptions', True)) }}
{%- set history_or_subscription = 'subscription_history' 
    if var('stripe__using_subscription_history', stripe.does_table_exist('subscription_history')=='exists') 
    else 'subscription' -%}
{{
    fivetran_utils.union_data(
        table_identifier=history_or_subscription, 
        database_variable='stripe_database', 
        schema_variable='stripe_schema', 
        default_database=target.database,
        default_schema='stripe',
        default_variable=history_or_subscription,
        union_schema_variable='stripe_union_schemas',
        union_database_variable='stripe_union_databases'
    )
}}