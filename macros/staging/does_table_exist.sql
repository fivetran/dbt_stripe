{%- macro does_table_exist(table_name) -%}
{{ adapter.dispatch('does_table_exist', 'stripe')(table_name) }}
{%- endmacro %}

{%- macro default__does_table_exist(table_name) -%}
    {%- if execute -%}
        {%- set source_relation = adapter.get_relation(
            database=var('stripe_database', target.database),
            schema=var('stripe_schema', 'stripe'),
            identifier=var('stripe_' ~ table_name ~ '_identifier', table_name)
            ) -%}
        {{ return('exists' if source_relation is not none) }}
    {%- endif -%}
{%- endmacro -%}