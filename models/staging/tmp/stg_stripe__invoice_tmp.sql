{{ config(enabled=var('stripe__using_invoices', True)) }}

{% if var('stripe_sources') != [] %}

{{
    stripe.stripe_union_connections(
        connection_dictionary='stripe_sources',
        single_source_name='stripe',
        single_table_name='invoice'
    )
}}

{% else %}

{{
    fivetran_utils.union_data(
        table_identifier='invoice',
        database_variable='stripe_database',
        schema_variable='stripe_schema',
        default_database=target.database,
        default_schema='stripe',
        default_variable='invoice',
        union_schema_variable='stripe_union_schemas',
        union_database_variable='stripe_union_databases'

    )
}}

{% endif %}
