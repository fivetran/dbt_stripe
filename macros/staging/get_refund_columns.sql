{% macro get_refund_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "amount", "datatype": dbt.type_int()},
    {"name": "balance_transaction_id", "datatype": dbt.type_string()},
    {"name": "charge_id", "datatype": dbt.type_string()},
    {"name": "payment_intent_id", "datatype": dbt.type_string()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "currency", "datatype": dbt.type_string()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "failure_balance_transaction_id", "datatype": dbt.type_string()},
    {"name": "failure_reason", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "metadata", "datatype": dbt.type_string()},
    {"name": "reason", "datatype": dbt.type_string()},
    {"name": "receipt_number", "datatype": dbt.type_string()},
    {"name": "status", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
