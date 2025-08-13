{% macro livemode_predicate() %}

    where cast(livemode as {{ dbt.type_boolean() }} ) = {{ var('stripe__using_livemode', true) }}

{% endmacro %}
