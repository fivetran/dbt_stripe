{% macro get_credit_note_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "amount", "datatype": dbt.type_int()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "currency", "datatype": dbt.type_string()},
    {"name": "discount_amount", "datatype": dbt.type_int()},
    {"name": "subtotal", "datatype": dbt.type_int()},
    {"name": "total", "datatype": dbt.type_int()},
    {"name": "livemode", "datatype": "boolean"},
    {"name": "memo", "datatype": dbt.type_string()},
    {"name": "metadata", "datatype": dbt.type_string()},
    {"name": "number", "datatype": dbt.type_string()},
    {"name": "pdf", "datatype": dbt.type_string()},
    {"name": "reason", "datatype": dbt.type_string()},
    {"name": "status", "datatype": dbt.type_string()},
    {"name": "type", "datatype": dbt.type_string()},
    {"name": "voided_at", "datatype": dbt.type_timestamp()},
    {"name": "customer_balance_transaction", "datatype": dbt.type_int()},
    {"name": "invoice_id", "datatype": dbt.type_string()},
    {"name": "refund_id", "datatype": dbt.type_string()},
] %}

{{ return(columns) }}

{% endmacro %}
