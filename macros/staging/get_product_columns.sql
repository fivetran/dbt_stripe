{% macro get_product_columns() %}

{% set columns = [
    {"name": "fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "active", "datatype": "boolean","alias": "is_active"},
    {"name": "attributes", "datatype": dbt.type_string()},
    {"name": "caption", "datatype": dbt.type_string()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "deactivate_on", "datatype": dbt.type_timestamp()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "images", "datatype":  dbt.type_string()},
    {"name": "is_deleted", "datatype": "boolean"},
    {"name": "livemode", "datatype": "boolean"},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "shippable", "datatype": "boolean"},
    {"name": "statement_descriptor", "datatype": dbt.type_string()},
    {"name": "type", "datatype": dbt.type_string()},
    {"name": "unit_label", "datatype": dbt.type_string()},
    {"name": "updated", "datatype": dbt.type_timestamp()},
    {"name": "url", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
