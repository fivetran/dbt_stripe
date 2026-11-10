{#-
    Compare the columns the package expects for a Stripe source table against the columns in the
    SOURCE table(s) the staging layer reads from. The source is what changes, so it is read
    directly, not through the built stg_stripe__<table>_tmp view (only a copy that goes stale).

    Everything is keyed by the source table name exactly as in src_stripe.yml (account, price,
    plan, subscription, subscription_history, ...), never by staging model name.

    get_column_diff(source_name) returns only the differences, as a dict:
      missing:        expected columns absent from the source (fill_staging_columns null-fills these)
      extra:          source columns the package doesn't model
      source_missing: true if no source table was found (then `missing` is every expected column)
      source_schemas: schema(s) the source was found in (more than one when schemas are unioned)

    When several source relations are unioned (schemas, databases, or connections), a column counts
    as present if any of them has it, matching how the union is built.

    At parse time (execute is false) the source can't be inspected, so empty lists are returned.
-#}

{#- Expected columns per source table name. A static map, so adding a table is one edit here next to
    its get_<table>_columns() macro. price/plan and subscription/subscription_history share a list
    because the staging model reads whichever of the pair exists. -#}
{% macro stripe_expected_columns() %}
    {{ return({
        'account': stripe.get_account_columns(),
        'balance_transaction': stripe.get_balance_transaction_columns(),
        'card': stripe.get_card_columns(),
        'charge': stripe.get_charge_columns(),
        'coupon': stripe.get_coupon_columns(),
        'credit_note': stripe.get_credit_note_columns(),
        'credit_note_line_item': stripe.get_credit_note_line_item_columns(),
        'customer': stripe.get_customer_columns(),
        'discount': stripe.get_discount_columns(),
        'dispute': stripe.get_dispute_columns(),
        'fee': stripe.get_fee_columns(),
        'invoice': stripe.get_invoice_columns(),
        'invoice_line_item': stripe.get_invoice_line_item_columns(),
        'payment_intent': stripe.get_payment_intent_columns(),
        'payment_method': stripe.get_payment_method_columns(),
        'payment_method_card': stripe.get_payment_method_card_columns(),
        'payout': stripe.get_payout_columns(),
        'payout_balance_transaction': stripe.get_payout_balance_transaction_columns(),
        'price': stripe.get_price_plan_columns(),
        'plan': stripe.get_price_plan_columns(),
        'product': stripe.get_product_columns(),
        'refund': stripe.get_refund_columns(),
        'subscription': stripe.get_subscription_columns(),
        'subscription_history': stripe.get_subscription_columns(),
        'subscription_discount': stripe.get_subscription_discount_columns(),
        'subscription_item': stripe.get_subscription_item_columns(),
        'transfer': stripe.get_transfer_columns()
    }) }}
{% endmacro %}

{#- The source table a staging model reads. Same as the staging name except where the _tmp model
    chooses between two, using the same vars and does_table_exist default as that model:
      price_plan   -> price | plan
      subscription -> subscription_history | subscription -#}
{% macro stripe_source_table_name(staging_table) %}
    {% if staging_table == 'price_plan' %}
        {{ return('price' if var('stripe__using_price', stripe.does_table_exist('price') == 'exists') else 'plan') }}
    {% elif staging_table == 'subscription' %}
        {{ return('subscription_history' if var('stripe__using_subscription_history', stripe.does_table_exist('subscription_history') == 'exists') else 'subscription') }}
    {% endif %}
    {{ return(staging_table) }}
{% endmacro %}

{#- Resolve the source relation(s) for a source table the same way stg_stripe__<table>_tmp does, in the
    same order: union schemas, union databases, stripe_sources connections, then the single source.
    This mirrors fivetran_utils.union_data / union_connections, which don't expose the relations. -#}
{% macro stripe_source_relations(source_name) %}
    {% set relations = [] %}
    {% set union_schemas = var('stripe_union_schemas', []) %}
    {% set union_databases = var('stripe_union_databases', []) %}
    {% set connections = var('stripe_sources', []) %}
    {% set has_defined_sources = var('has_defined_sources', false) %}

    {% if union_schemas | length > 0 %}
        {% for schema in union_schemas %}
            {% if has_defined_sources %}
                {% set src = source(schema, source_name) %}
                {% set rel = adapter.get_relation(database=src.database, schema=src.schema, identifier=src.identifier) %}
            {% else %}
                {% set rel = adapter.get_relation(database=var('stripe_database', target.database), schema=schema, identifier=source_name) %}
            {% endif %}
            {% if rel is not none %}{% do relations.append(rel) %}{% endif %}
        {% endfor %}

    {% elif union_databases | length > 0 %}
        {% for database in union_databases %}
            {% if has_defined_sources %}
                {% set src = source('stripe', source_name) %}
                {% set rel = adapter.get_relation(database=src.database, schema=src.schema, identifier=src.identifier) %}
            {% else %}
                {% set rel = adapter.get_relation(database=database, schema=var('stripe_schema', 'stripe'), identifier=source_name) %}
            {% endif %}
            {% if rel is not none %}{% do relations.append(rel) %}{% endif %}
        {% endfor %}

    {% elif connections | length > 0 %}
        {% for connection in connections %}
            {% if has_defined_sources %}
                {% set src = source(connection.name, source_name) %}
                {% set rel = adapter.get_relation(database=src.database, schema=src.schema, identifier=src.identifier) %}
            {% else %}
                {% set rel = adapter.get_relation(
                    database=connection.database if connection.database else target.database,
                    schema=connection.schema if connection.schema else 'stripe',
                    identifier=var('stripe_' ~ source_name ~ '_identifier', source_name)) %}
            {% endif %}
            {% if rel is not none %}{% do relations.append(rel) %}{% endif %}
        {% endfor %}

    {% else %}
        {% set src = source('stripe', source_name) %}
        {% set rel = adapter.get_relation(database=src.database, schema=src.schema, identifier=src.identifier) %}
        {% if rel is not none %}{% do relations.append(rel) %}{% endif %}
    {% endif %}

    {{ return(relations) }}
{% endmacro %}

{% macro get_column_diff(source_name) %}
    {% if not execute %}
        {{ return({'missing': [], 'extra': [], 'source_missing': false, 'source_schemas': []}) }}
    {% endif %}

    {% set expected_by_source = stripe.stripe_expected_columns() %}
    {% if source_name not in expected_by_source %}
        {{ exceptions.raise_compiler_error("get_column_diff: unknown source table '" ~ source_name ~ "'. Expected one of: " ~ expected_by_source.keys() | sort | join(', ')) }}
    {% endif %}

    {% set relations = stripe.stripe_source_relations(source_name) %}
    {% set actual = [] %}
    {% for relation in relations %}
        {% for column in adapter.get_columns_in_relation(relation) %}
            {% do actual.append(column.name | lower) %}
        {% endfor %}
    {% endfor %}
    {% set actual = actual | unique | list %}
    {% set expected = expected_by_source[source_name] | map(attribute='name') | map('lower') | list %}

    {{ return({
        'missing': expected | reject('in', actual) | list,
        'extra': actual | reject('in', expected) | list,
        'source_missing': relations | length == 0,
        'source_schemas': relations | map(attribute='schema') | unique | list
    }) }}
{% endmacro %}

{#-
    Source tables the package reads right now. Staging models come from the graph, so disabled ones
    (e.g. credit notes unless enabled) are skipped; each is mapped to the source table it reads, so
    price_plan gives price or plan, and subscription gives subscription or subscription_history.
-#}
{% macro stripe_source_tables() %}
    {% set expected_by_source = stripe.stripe_expected_columns() %}
    {% set tables = [] %}
    {% for node in graph.nodes.values() if node.resource_type == 'model' and node.package_name == 'stripe' and node.name.startswith('stg_stripe__') and node.name.endswith('_tmp') %}
        {% set source_name = stripe.stripe_source_table_name(node.name[12:-4]) %}
        {% if source_name in expected_by_source %}
            {% do tables.append(source_name) %}
        {% endif %}
    {% endfor %}
    {{ return(tables | sort) }}
{% endmacro %}

{#-
    {source_name: {missing, extra, source_missing, source_schemas}} for every source table with any
    difference. This is the package's entry point for the fivetran-source-config skill.

    Run directly with `dbt run-operation stripe.get_column_diffs`, it also logs the result as JSON,
    because run-operation discards return values. It has to be run that way (not called from another
    package's macro or `dbt show`), since only run-operation resolves var() in this package's scope.
-#}
{% macro get_column_diffs() %}
    {% set result = {} %}
    {% for source_name in stripe.stripe_source_tables() %}
        {% set diff = stripe.get_column_diff(source_name) %}
        {% if diff.missing or diff.extra %}
            {% do result.update({source_name: diff}) %}
        {% endif %}
    {% endfor %}
    {% if execute and flags.WHICH == 'run-operation' %}
        {{ log(tojson(result), info=True) }}
    {% endif %}
    {{ return(result) }}
{% endmacro %}
