{{ config(enabled=var('stripe__using_subscriptions', True)) }}

{{
    fivetran_utils.union_data(
        table_identifier='subscription_item', 
        database_variable='stripe_database', 
        schema_variable='stripe_schema', 
        default_database=target.database,
        default_schema='stripe',
        default_variable='subscription_item',
        union_schema_variable='stripe_union_schemas',
        union_database_variable='stripe_union_databases'
    )
}}