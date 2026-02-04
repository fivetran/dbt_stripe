{% macro select_metadata_columns(relation_alias, var_name, prefix=None) %}
  {%- set properties = var(var_name, []) -%}
  {%- set prefix = prefix if prefix is not none else relation_alias -%}

  {%- for property in properties -%}
    {%- if property is mapping -%}
      {%- set col = property.alias if property.alias else property.name -%}
    {%- else -%}
      {%- set col = property -%}
    {%- endif -%}

{{ relation_alias }}.{{ adapter.quote(col) }} as {{ prefix }}_{{ col }},
  {%- endfor -%}
{% endmacro %}