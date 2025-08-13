{% macro get_credit_note_line_item_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "credit_note_id", "datatype": dbt.type_string()},
    {"name": "amount", "datatype": dbt.type_int()},
    {"name": "discount_amount", "datatype": dbt.type_int()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "livemode", "datatype": "boolean"},
    {"name": "quantity", "datatype": dbt.type_int()},
    {"name": "type", "datatype": dbt.type_string()},
    {"name": "unit_amount", "datatype": dbt.type_int()},
    {"name": "unit_amount_decimal", "datatype": dbt.type_int()},
] %}

{{ return(columns) }}

{% endmacro %}
