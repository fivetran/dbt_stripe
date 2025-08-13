{% macro get_account_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "business_profile_name", "datatype": dbt.type_string()},
    {"name": "business_profile_mcc", "datatype": dbt.type_string()},
    {"name": "business_type", "datatype": dbt.type_string()},
    {"name": "charges_enabled", "datatype": "boolean"},
    {"name": "company_address_city", "datatype": dbt.type_string()},
    {"name": "company_address_country", "datatype": dbt.type_string()},
    {"name": "company_address_line_1", "datatype": dbt.type_string()},
    {"name": "company_address_line_2", "datatype": dbt.type_string()},
    {"name": "company_address_postal_code", "datatype": dbt.type_string()},
    {"name": "company_address_state", "datatype": dbt.type_string()},
    {"name": "company_name", "datatype": dbt.type_string()},
    {"name": "company_phone", "datatype": dbt.type_string()},
    {"name": "country", "datatype": dbt.type_string()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "default_currency", "datatype": dbt.type_string()},
    {"name": "details_submitted", "datatype": "boolean"},
    {"name": "email", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "is_deleted", "datatype": "boolean"},
    {"name": "metadata", "datatype": dbt.type_string()},
    {"name": "payouts_enabled", "datatype": "boolean"},
    {"name": "type", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
