{% macro get_invoice_line_item_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "amount", "datatype": dbt.type_int()},
    {"name": "currency", "datatype": dbt.type_string()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "discountable", "datatype": "boolean"},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "invoice_id", "datatype": dbt.type_string()},
    {"name": "invoice_item_id", "datatype": dbt.type_string()},
    {"name": "livemode", "datatype": "boolean"},
    {"name": "metadata", "datatype": dbt.type_string()},
    {"name": "period_end", "datatype": dbt.type_timestamp()},
    {"name": "period_start", "datatype": dbt.type_timestamp()},
    {"name": "plan_id", "datatype": dbt.type_string()},
    {"name": "price_id", "datatype": dbt.type_string()},
    {"name": "proration", "datatype": "boolean"},
    {"name": "quantity", "datatype": dbt.type_int()},
    {"name": "subscription_id", "datatype": dbt.type_string()},
    {"name": "subscription_item_id", "datatype": dbt.type_string()},
    {"name": "type", "datatype": dbt.type_string()},
    {"name": "unique_id", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
