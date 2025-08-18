{% macro get_card_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "account_id", "datatype": dbt.type_string()},
    {"name": "address_city", "datatype": dbt.type_string()},
    {"name": "address_country", "datatype": dbt.type_string()},
    {"name": "address_line_1", "datatype": dbt.type_string()},
    {"name": "address_line_2", "datatype": dbt.type_string()},
    {"name": "address_state", "datatype": dbt.type_string()},
    {"name": "address_zip", "datatype": dbt.type_string()},
    {"name": "brand", "datatype": dbt.type_string()},
    {"name": "country", "datatype": dbt.type_string()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "customer_id", "datatype": dbt.type_string()},
    {"name": "funding", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "metadata", "datatype": dbt.type_string(), "alias": "card_metadata"},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "recipient", "datatype": dbt.type_string()},
    {"name": "wallet_type", "datatype": dbt.type_string()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('card_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
