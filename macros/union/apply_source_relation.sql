{% macro apply_source_relation() -%}

{{ adapter.dispatch('apply_source_relation', 'stripe') () }}

{%- endmacro %}

{% macro default__apply_source_relation() -%}

{% if var('stripe_sources', []) != [] %}
, _dbt_source_relation as source_relation
{% elif var('union_schemas', []) != []  or var('union_databases', []) != [] %}
{{ fivetran_utils.source_relation() }}
{% else %}
, '{{ var("stripe_database", target.database) }}' || '.'|| '{{ var("stripe_schema", "stripe") }}' as source_relation
{% endif %}

{%- endmacro %}