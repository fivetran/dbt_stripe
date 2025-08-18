{% macro get_price_plan_columns() %}

{% if var('stripe__using_price', stripe.does_table_exist('price')=='exists') %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "active", "datatype": "boolean","alias": "is_active"},
    {"name": "billing_scheme", "datatype": dbt.type_string()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "currency", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "is_deleted", "datatype": "boolean"},
    {"name": "livemode", "datatype": "boolean"},
    {"name": "metadata", "datatype": dbt.type_string()},
    {"name": "nickname", "datatype": dbt.type_string()},
    {"name": "product_id", "datatype": dbt.type_string()},
    {"name": "recurring_aggregate_usage", "datatype": dbt.type_string()},
    {"name": "recurring_interval", "datatype": dbt.type_string()},
    {"name": "recurring_interval_count", "datatype": dbt.type_int()},
    {"name": "recurring_usage_type", "datatype": dbt.type_string()},
    {"name": "unit_amount", "datatype": dbt.type_int()},
    {"name": "unit_amount_decimal", "datatype": dbt.type_string()}
] %}

{% else %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "active", "datatype": "boolean","alias": "is_active"},
    {"name": "aggregate_usage", "datatype": dbt.type_string(),"alias": "recurring_aggregate_usage"},
    {"name": "amount", "datatype": dbt.type_int(),"alias": "unit_amount"},
    {"name": "billing_scheme", "datatype": dbt.type_string()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "currency", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "interval_count", "datatype": dbt.type_int(),"alias": "recurring_interval_count"},
    {"name": "is_deleted", "datatype": "boolean"},
    {"name": "livemode", "datatype": "boolean"},
    {"name": "metadata", "datatype": dbt.type_string()},
    {"name": "nickname", "datatype": dbt.type_string()},
    {"name": "product_id", "datatype": dbt.type_string()},
    {"name": "trial_period_days", "datatype": dbt.type_int()},
    {"name": "usage_type", "datatype": dbt.type_string(),"alias": "recurring_usage_type"}
] %}

{% if target.type in ('bigquery', 'spark', 'databricks') %}
    {{ columns.append( {"name": 'interval', "datatype": dbt.type_string(), "quote": True, "alias": "recurring_interval" } ) }}

{% else %}
    {{ columns.append( {"name": "interval", "datatype": dbt.type_string(), "alias": "recurring_interval"} ) }}

{% endif %}


{% endif %}

{{ return(columns) }}

{% endmacro %}
