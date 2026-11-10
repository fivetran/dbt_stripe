{% macro get_subscription_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_active", "datatype": "boolean"},
    {"name": "billing", "datatype": dbt.type_string()},
    {"name": "billing_cycle_anchor", "datatype": dbt.type_timestamp()},
    {"name": "cancel_at", "datatype": dbt.type_timestamp()},
    {"name": "cancel_at_period_end", "datatype": "boolean"},
    {"name": "canceled_at", "datatype": dbt.type_timestamp()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "current_period_end", "datatype": dbt.type_timestamp()},
    {"name": "current_period_start", "datatype": dbt.type_timestamp()},
    {"name": "customer_id", "datatype": dbt.type_string()},
    {"name": "days_until_due", "datatype": dbt.type_int()},
    {"name": "ended_at", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "latest_invoice_id", "datatype": dbt.type_string()},
    {"name": "default_payment_method_id", "datatype": dbt.type_string()},
    {"name": "pending_setup_intent_id", "datatype": dbt.type_string()},
    {"name": "livemode", "datatype": "boolean"},
    {"name": "metadata", "datatype": dbt.type_string()},
    {"name": "start_date", "datatype": dbt.type_timestamp()},
    {"name": "status", "datatype": dbt.type_string()},
    {"name": "pause_collection_behavior", "datatype": dbt.type_string()},
    {"name": "pause_collection_resumes_at", "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
