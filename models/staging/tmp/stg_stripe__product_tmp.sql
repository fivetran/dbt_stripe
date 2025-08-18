{{ config(enabled=var('stripe__using_subscriptions', True)) }}

{{
    fivetran_utils.union_data(
        table_identifier='product', 
        database_variable='stripe_database', 
        schema_variable='stripe_schema', 
        default_database=target.database,
        default_schema='stripe',
        default_variable='product',
        union_schema_variable='stripe_union_schemas',
        union_database_variable='stripe_union_databases'
    )
}}