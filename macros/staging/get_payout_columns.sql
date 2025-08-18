{% macro get_payout_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "amount", "datatype": dbt.type_int()},
    {"name": "arrival_date", "datatype": dbt.type_timestamp()},
    {"name": "automatic", "datatype": "boolean"},
    {"name": "balance_transaction_id", "datatype": dbt.type_string()},
    {"name": "connected_account_id", "datatype": dbt.type_string()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "currency", "datatype": dbt.type_string()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "destination_bank_account_id", "datatype": dbt.type_string()},
    {"name": "destination_card_id", "datatype": dbt.type_string()},
    {"name": "failure_balance_transaction_id", "datatype": dbt.type_string()},
    {"name": "failure_code", "datatype": dbt.type_string()},
    {"name": "failure_message", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "livemode", "datatype": "boolean"},
    {"name": "metadata", "datatype": dbt.type_string()},
    {"name": "method", "datatype": dbt.type_string()},
    {"name": "source_type", "datatype": dbt.type_string()},
    {"name": "statement_descriptor", "datatype": dbt.type_string()},
    {"name": "status", "datatype": dbt.type_string()},
    {"name": "type", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
