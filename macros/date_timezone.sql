{% macro date_timezone(column) -%}

date(
    {{ column }}
    {% if var('stripe_timezone', none) %} , "{{ var('stripe_timezone') }}" {% endif %}
    )

{%- endmacro %}