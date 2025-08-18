{% macro get_fee_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "amount", "datatype": dbt.type_int()},
    {"name": "application", "datatype": dbt.type_string()},
    {"name": "balance_transaction_id", "datatype": dbt.type_string()},
    {"name": "connected_account_id", "datatype": dbt.type_string()},
    {"name": "currency", "datatype": dbt.type_string()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "index", "datatype": dbt.type_int()},
    {"name": "type", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
