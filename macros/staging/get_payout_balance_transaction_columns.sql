{% macro get_payout_balance_transaction_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "payout_id", "datatype": dbt.type_string()},
    {"name": "balance_transaction_id", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
