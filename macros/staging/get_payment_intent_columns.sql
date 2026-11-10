{% macro get_payment_intent_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "amount", "datatype": dbt.type_int()},
    {"name": "amount_capturable", "datatype": dbt.type_int()},
    {"name": "amount_received", "datatype": dbt.type_int()},
    {"name": "application", "datatype": dbt.type_string()},
    {"name": "application_fee_amount", "datatype": dbt.type_int()},
    {"name": "canceled_at", "datatype": dbt.type_timestamp()},
    {"name": "cancellation_reason", "datatype": dbt.type_string()},
    {"name": "capture_method", "datatype": dbt.type_string()},
    {"name": "confirmation_method", "datatype": dbt.type_string()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "currency", "datatype": dbt.type_string()},
    {"name": "customer_id", "datatype": dbt.type_string()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "livemode", "datatype": "boolean"},
    {"name": "metadata", "datatype": dbt.type_string()},
    {"name": "payment_method_id", "datatype": dbt.type_string()},
    {"name": "receipt_email", "datatype": dbt.type_string()},
    {"name": "statement_descriptor", "datatype": dbt.type_string()},
    {"name": "status", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
