{% macro get_transfer_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "amount", "datatype": dbt.type_int()},
    {"name": "amount_reversed", "datatype": dbt.type_int()},
    {"name": "balance_transaction_id", "datatype": dbt.type_string()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "currency", "datatype": dbt.type_string()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "destination", "datatype": dbt.type_string()},
    {"name": "destination_payment", "datatype": dbt.type_string()},
    {"name": "destination_payment_id", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "livemode", "datatype": "boolean"},
    {"name": "metadata", "datatype": dbt.type_string()},
    {"name": "reversed", "datatype": "boolean"},
    {"name": "source_transaction", "datatype": dbt.type_string()},
    {"name": "source_transaction_id", "datatype": dbt.type_string()},
    {"name": "source_type", "datatype": dbt.type_string()},
    {"name": "transfer_group", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
