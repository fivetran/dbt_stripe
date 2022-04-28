{% macro date_timezone(column) -%}

{{ adapter.dispatch('date_timezone', 'stripe')(column)  }}

{%- endmacro %}

{% macro bigquery__date_timezone(column) -%}

date(
    {{ column }}
    {% if var('stripe_timezone', none) %} , "{{ var('stripe_timezone') }}" {% endif %}
    )

{%- endmacro %}

{% macro postgres__date_timezone(column) -%}

{% set converted_date %}

{% if var('stripe_timezone', none) %}
    {{ column }} at time zone '{{ var('stripe_timezone') }}'
{% else %}
    {{ column }}
{% endif %}

{% endset %}

{{ dbt_utils.date_trunc('day',converted_date) }}

{%- endmacro %}


{% macro redshift__date_timezone(column) -%}

{% set converted_date %}

{% if var('stripe_timezone', none) %}
    convert_timezone('{{ var("stripe_timezone") }}', {{ column }})
{% else %}
    {{ column }}
{% endif %}

{% endset %}

{{ dbt_utils.date_trunc('day',converted_date) }}

{%- endmacro %}


{% macro default__date_timezone(column) -%}

{% set converted_date %}

{% if var('stripe_timezone', none) %}
    convert_timezone('{{ var("stripe_timezone") }}', {{ column }})
{% else %}
    {{ column }}
{% endif %}

{% endset %}

{{ dbt_utils.date_trunc('day',converted_date) }}

{%- endmacro %}