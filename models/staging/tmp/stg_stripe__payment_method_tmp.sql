{{ config(enabled=var('stripe__using_payment_method', True)) }}

{% if var('stripe_sources') != [] %}

{{
    stripe.stripe_union_connections(
        connection_dictionary='stripe_sources',
        single_source_name='stripe',
        single_table_name='payment_method'
    )
}}

{% else %}

{{
    fivetran_utils.union_data(
        table_identifier='payment_method',
        database_variable='stripe_database',
        schema_variable='stripe_schema',
        default_database=target.database,
        default_schema='stripe',
        default_variable='payment_method',
        union_schema_variable='stripe_union_schemas',
        union_database_variable='stripe_union_databases'

    )
}}

{% endif %}
