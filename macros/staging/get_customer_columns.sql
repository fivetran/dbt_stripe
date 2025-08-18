{% macro get_customer_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "account_balance", "datatype": dbt.type_int()},
    {"name": "address_city", "datatype": dbt.type_string()},
    {"name": "address_country", "datatype": dbt.type_string()},
    {"name": "address_line_1", "datatype": dbt.type_string()},
    {"name": "address_line_2", "datatype": dbt.type_string()},
    {"name": "address_postal_code", "datatype": dbt.type_string()},
    {"name": "address_state", "datatype": dbt.type_string()},
    {"name": "balance", "datatype": dbt.type_int()},
    {"name": "bank_account_id", "datatype": dbt.type_string()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "currency", "datatype": dbt.type_string()},
    {"name": "default_card_id", "datatype": dbt.type_string()},
    {"name": "delinquent", "datatype": "boolean"},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "email", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "invoice_prefix", "datatype": dbt.type_string()},
    {"name": "invoice_settings_default_payment_method", "datatype": dbt.type_string()},
    {"name": "invoice_settings_footer", "datatype": dbt.type_string()},
    {"name": "is_deleted", "datatype": "boolean"},
    {"name": "livemode", "datatype": "boolean"},
    {"name": "metadata", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "phone", "datatype": dbt.type_string()},
    {"name": "shipping_address_city", "datatype": dbt.type_string()},
    {"name": "shipping_address_country", "datatype": dbt.type_string()},
    {"name": "shipping_address_line_1", "datatype": dbt.type_string()},
    {"name": "shipping_address_line_2", "datatype": dbt.type_string()},
    {"name": "shipping_address_postal_code", "datatype": dbt.type_string()},
    {"name": "shipping_address_state", "datatype": dbt.type_string()},
    {"name": "shipping_carrier", "datatype": dbt.type_string()},
    {"name": "shipping_name", "datatype": dbt.type_string()},
    {"name": "shipping_phone", "datatype": dbt.type_string()},
    {"name": "shipping_tracking_number", "datatype": dbt.type_string()},
    {"name": "source_id", "datatype": dbt.type_string()},
    {"name": "tax_exempt", "datatype": dbt.type_string()},
    {"name": "tax_info_tax_id", "datatype": dbt.type_string()},
    {"name": "tax_info_type", "datatype": dbt.type_string()},
    {"name": "tax_info_verification_status", "datatype": dbt.type_string()},
    {"name": "tax_info_verification_verified_name", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
