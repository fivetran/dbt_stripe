{% macro get_coupon_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "amount_off", "datatype": dbt.type_int()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "currency", "datatype": dbt.type_string()},
    {"name": "duration", "datatype": dbt.type_string()},
    {"name": "duration_in_months", "datatype": dbt.type_int()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "livemode", "datatype": "boolean"},
    {"name": "max_redemptions", "datatype": dbt.type_int()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "percent_off", "datatype": dbt.type_float()},
    {"name": "redeem_by", "datatype": dbt.type_timestamp()},
    {"name": "times_redeemed", "datatype": dbt.type_int()},
    {"name": "valid", "datatype": "boolean"}
] %}

{{ return(columns) }}

{% endmacro %}
