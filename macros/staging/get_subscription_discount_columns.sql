{% macro get_subscription_discount_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "checkout_session_id", "datatype": dbt.type_string()},
    {"name": "coupon_id", "datatype": dbt.type_string()},
    {"name": "customer_id", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "invoice_id", "datatype": dbt.type_string()},
    {"name": "invoice_item_id", "datatype": dbt.type_string()},
    {"name": "subscription_id", "datatype": dbt.type_string()}
] %}

{% if target.type == 'snowflake' %}
    {{ columns.append({"name": "END", "datatype": dbt.type_string(), "quote": True, "alias": "end_at"}) }},
    {{ columns.append({"name": "START", "datatype": dbt.type_string(), "quote": True, "alias": "start_at"}) }}
{% else %}
    {{ columns.append({"name": "end", "datatype": dbt.type_string(), "quote": True, "alias": "end_at"}) }},
    {{ columns.append({"name": "start", "datatype": dbt.type_string(), "quote": True, "alias": "start_at"}) }}
{% endif %}

{{ return(columns) }}

{% endmacro %}