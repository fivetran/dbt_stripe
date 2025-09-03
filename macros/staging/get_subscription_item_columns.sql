{% macro get_subscription_item_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "current_period_end", "datatype": dbt.type_timestamp()},
    {"name": "current_period_start", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "metadata", "datatype": dbt.type_string()},
    {"name": "plan_id", "datatype": dbt.type_string()},
    {"name": "quantity", "datatype": dbt.type_int()},
    {"name": "subscription_id", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
