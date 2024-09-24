{%- macro stripe_include_source_relation_in_join(cte_a, cte_b) %}
    {%- if var('stripe_union_schemas', [])|length > 1 or var('stripe_union_databases', [])|length > 1 %}
        and {{ cte_a }}.source_relation = {{ cte_b }}.source_relation
    {% endif -%}
{% endmacro %}