{{ config(enabled=var('stripe__using_subscriptions', True)) }}

{%- set price_or_plan = 'price'
    if var('stripe__using_price', stripe.does_table_exist('price')=='exists')
    else 'plan' -%}

{% if var('stripe_union_schemas', []) | length > 0 or var('stripe_union_databases', []) | length > 0 %}

{{
    fivetran_utils.union_data(
        table_identifier=price_or_plan,
        database_variable='stripe_database',
        schema_variable='stripe_schema',
        default_database=target.database,
        default_schema='stripe',
        default_variable=price_or_plan,
        union_schema_variable='stripe_union_schemas',
        union_database_variable='stripe_union_databases'

    )
}}

{% else %}

{{
    fivetran_utils.union_connections(
        connection_dictionary='stripe_sources',
        single_source_name='stripe',
        single_table_name=price_or_plan
    )
}}

{% endif %}