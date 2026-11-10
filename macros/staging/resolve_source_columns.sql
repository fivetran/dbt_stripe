{% macro resolve_source_columns(table_name, staging_columns, payload_key=none) %}
{#
    POC: builds the body of a `stg_stripe__<table>_tmp` model from the stripe__source_config
    payload var, with no warehouse introspection (no adapter.get_columns_in_relation or
    adapter.get_relation). Unions connections and resolves columns in one pass, since a
    `union all` needs every leg's column list aligned and that list comes from the payload.
    Replaces fivetran_utils.union_connections/union_data in the tmp models and
    fivetran_utils.fill_staging_columns/apply_source_relation in the staging models.

    Connections come from stripe_sources, else stripe_union_schemas / stripe_union_databases
    (each turned into a database + schema pair), else the single `stripe` source.

    Payload shape (keyed by connection, then by the connector's own table name, then by the
    connector's own column name -> the column's current destination name):

        stripe__source_config:
          <database>.<schema>:          # or just <schema> when the schema name is unique
            <payload_key>:              # e.g. customer
              name: <destination table name>
              columns:
                <source_column_name>: <current destination column name>

    Connection keys are `database.schema` first, then `schema` alone. Schema alone isn't enough
    once you union: two Stripe connections in different projects/databases can both land in a
    schema called `stripe`. When the var has exactly one entry and you aren't unioning, that
    entry is used regardless of its key.

    Per connection:
      - No payload entry for the connection at all -> every column is assumed present under its
        own name (the connector's default, unrenamed behavior).
      - Connection entry exists but has no entry for this table -> the connector doesn't sync the
        table for that connection, so that union leg is skipped entirely.
      - Table entry exists -> each staging column is selected from its mapped current name, or
        `cast(null as datatype)` when the column isn't in the payload.

    A column's source name is `source_name` on its get_*_columns dict, defaulting to `name`.
    Stripe's connector columns are already snake_case, so nearly all match. Fivetran metadata
    columns (names containing `_fivetran`) skip the lookup and are always passed through.

    When more than one leg is unioned, every column is cast to its declared datatype so the
    legs line up positionally even when one leg null-fills a column the other has.

    Usage in models/staging/tmp/stg_stripe__customer_tmp.sql:
        {{ stripe.resolve_source_columns(table_name='customer', staging_columns=stripe.get_customer_columns()) }}
#}
{%- set payload_key = payload_key or table_name -%}
{%- set identifier = var('stripe_' ~ table_name ~ '_identifier', table_name) -%}
{%- set full_source_config = var('stripe__source_config', {}) or {} -%}
{%- set connections = var('stripe_sources', []) or [] -%}
{%- if connections | length == 0 -%}
    {%- set connections = [] -%}
    {%- for schema in var('stripe_union_schemas', []) -%}
        {%- do connections.append({'database': var('stripe_database', target.database), 'schema': schema}) -%}
    {%- endfor -%}
    {%- for database in var('stripe_union_databases', []) -%}
        {%- do connections.append({'database': database, 'schema': var('stripe_schema', 'stripe')}) -%}
    {%- endfor -%}
{%- endif -%}
{%- set using_unioning = connections | length > 0 -%}

{# One entry per union leg: where it lives, and the column map that applies to it. #}
{%- set legs = [] -%}
{%- if using_unioning -%}
    {%- for connection in connections -%}
        {%- set database = connection.database or target.database -%}
        {%- set schema = connection.schema or 'stripe' -%}
        {%- if var('has_defined_sources', false) and connection.name -%}
            {%- set relation = source(connection.name, table_name) -%}
        {%- else -%}
            {%- set relation = api.Relation.create(database=database, schema=schema, identifier=identifier) -%}
        {%- endif -%}
        {%- do legs.append({'database': database, 'schema': schema, 'relation': relation}) -%}
    {%- endfor -%}
{%- else -%}
    {%- set relation = source('stripe', table_name) -%}
    {%- do legs.append({'database': relation.database, 'schema': relation.schema, 'relation': relation}) -%}
{%- endif -%}

{%- set resolved_legs = [] -%}
{%- for leg in legs -%}
    {%- set connection_key = (leg.database ~ '.' ~ leg.schema) | lower -%}
    {%- if not using_unioning and full_source_config | length == 1 -%}
        {%- set connection_config = full_source_config.values() | first -%}
    {%- elif connection_key in full_source_config -%}
        {%- set connection_config = full_source_config[connection_key] -%}
    {%- else -%}
        {%- set connection_config = full_source_config.get(leg.schema | lower) -%}
    {%- endif -%}

    {%- if connection_config is none -%}
        {# no entry for this connection: identity mapping #}
        {%- do resolved_legs.append({'leg': leg, 'columns': none}) -%}
    {%- elif payload_key in connection_config -%}
        {%- set table_config = connection_config[payload_key] or {} -%}
        {%- do resolved_legs.append({'leg': leg, 'columns': table_config.get('columns', {}) or {}}) -%}
    {%- endif -%}
    {# else: connection is configured but doesn't sync this table -> skip the leg #}
{%- endfor -%}

{%- set cast_columns = resolved_legs | length > 1 -%}

{%- if resolved_legs | length == 0 %}
    -- no configured connection syncs {{ payload_key }}; returning an empty, correctly typed relation
    select
        {%- for column in staging_columns %}
        cast(null as {{ column.datatype }}) as {% if 'alias' in column %}{{ column.alias }}{% else %}{{ fivetran_utils.quote_column(column) | trim }}{% endif %},
        {%- endfor %}
        cast(null as {{ dbt.type_string() }}) as source_relation
    limit {{ '0' if target.type != 'redshift' else '1' }}
{%- endif %}

{%- for resolved in resolved_legs %}
    select
        {%- for column in staging_columns %}
        {%- set output_name = column.alias if 'alias' in column else fivetran_utils.quote_column(column) | trim %}
        {%- if '_fivetran' in column.name or resolved.columns is none %}
            {%- set current_name = column.name %}
        {%- else %}
            {%- set current_name = resolved.columns.get(column.source_name or column.name) %}
        {%- endif %}
        {%- if current_name is none %}
        cast(null as {{ column.datatype }}) as {{ output_name }},
        {%- elif cast_columns %}
        cast({{ fivetran_utils.quote_column({"name": current_name, "quote": true}) | trim }} as {{ column.datatype }}) as {{ output_name }},
        {%- else %}
        {{ fivetran_utils.quote_column({"name": current_name, "quote": true}) | trim }} as {{ output_name }},
        {%- endif %}
        {%- endfor %}
        cast('{{ resolved.leg.database ~ "." ~ resolved.leg.schema }}' as {{ dbt.type_string() }}) as source_relation
    from {{ resolved.leg.relation }}
    {% if not loop.last %}union all{% endif %}
{%- endfor %}

{%- endmacro %}


{% macro source_config_has_table(payload_key) %}
{#
    POC: answers "does the connector sync this table?" from the stripe__source_config payload,
    with no warehouse introspection. True only if every configured connection syncs the table.
    With no payload set, returns true: the connector's current default tables (`price`,
    `subscription_history`) are assumed, and the stripe__using_* vars still override.
#}
{%- set full_source_config = var('stripe__source_config', {}) or {} -%}
{%- if full_source_config | length == 0 -%}
    {{ return(true) }}
{%- endif -%}
{%- for connection_config in full_source_config.values() -%}
    {%- if payload_key not in (connection_config or {}) -%}
        {{ return(false) }}
    {%- endif -%}
{%- endfor -%}
{{ return(true) }}
{%- endmacro %}
