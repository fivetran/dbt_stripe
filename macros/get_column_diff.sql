{#-
    get_column_diffs() compares the columns the package expects for each Stripe source table
    (get_<table>_columns()) with the columns in the source table(s) the package is configured to read,
    and returns only the sources that differ, keyed by source table name:

        {source table: {missing, extra, source_missing, source_schemas}}

      missing:        expected columns the source lacks (fill_staging_columns null-fills these)
      extra:          source columns the package doesn't model
      source_missing: no source table was found (then `missing` is every expected column)
      source_schemas: schema(s) the source was found in (several when connections are unioned)

    It reads the source tables themselves, not the built stg_stripe__<table>_tmp views, which only
    copy the source and go stale. With several connections a column counts as present if any of them
    has it, as in the union.

    This is the package's entry point for the fivetran-source-config skill. Run with
    `dbt run-operation stripe.get_column_diffs` it also logs the result as JSON, because run-operation
    discards return values. It has to be started that way: only run-operation resolves var() in this
    package's scope. Sibling macros are called as stripe.<macro>() so they resolve from outside it.
-#}

{#- Expected columns per source table name (as in src_stripe.yml). One entry per get_<table>_columns().
    price/plan and subscription/subscription_history share a list: the staging model reads whichever
    of each pair exists, and a source that isn't there is simply reported as source_missing. -#}
{% macro expected_columns() %}
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

{#- dbt's own record (graph.sources) of a declared source table, or none. -#}
{% macro source_node(source_name, table) %}
    {% for node in graph.sources.values() if node.source_name == source_name and node.name == table %}
        {{ return(node) }}
    {% endfor %}
    {{ return(none) }}
{% endmacro %}

{#- The relation(s) holding a source table: one per connection, found as stg_stripe__<table>_tmp finds
    them. Connections come from stripe_sources, else stripe_union_schemas / stripe_union_databases, else
    the single `stripe` source. Where sources are declared in dbt (has_defined_sources, or the single
    source) the declaration says where the table lives; otherwise the connection's database and schema
    do, with the table named by its stripe_<table>_identifier var (the union_schemas and union_databases
    modes name it by the plain source table name, as fivetran_utils.union_data does). Tables that aren't
    there are skipped. -#}
{% macro source_relations(table) %}
    {% set defined = var('has_defined_sources', false) %}
    {% set places = [] %}
    {% if var('stripe_sources', []) %}
        {% for c in var('stripe_sources') %}
            {% do places.append({'source': c.name, 'database': c.database or target.database, 'schema': c.schema or 'stripe', 'declared': defined, 'by_var': true}) %}
        {% endfor %}
    {% elif var('stripe_union_schemas', []) %}
        {% for s in var('stripe_union_schemas') %}
            {% do places.append({'source': s, 'database': var('stripe_database', target.database), 'schema': s, 'declared': defined, 'by_var': false}) %}
        {% endfor %}
    {% elif var('stripe_union_databases', []) %}
        {% for d in var('stripe_union_databases') %}
            {% do places.append({'source': 'stripe', 'database': d, 'schema': var('stripe_schema', 'stripe'), 'declared': false, 'by_var': false}) %}
        {% endfor %}
    {% else %}
        {% do places.append({'source': 'stripe', 'database': var('stripe_database', target.database), 'schema': var('stripe_schema', 'stripe'), 'declared': true, 'by_var': true}) %}
    {% endif %}

    {% set relations = [] %}
    {% for p in places %}
        {% set node = stripe.source_node(p.source, table) if p.declared else none %}
        {% set relation = adapter.get_relation(
            database=node.database if node else p.database,
            schema=node.schema if node else p.schema,
            identifier=node.identifier if node else (var('stripe_' ~ table ~ '_identifier', table) if p.by_var else table)) %}
        {% if relation is not none %}{% do relations.append(relation) %}{% endif %}
    {% endfor %}
    {{ return(relations) }}
{% endmacro %}

{% macro get_column_diffs() %}
    {% set result = {} %}
    {% if execute %}
        {% set expected_by_source = stripe.expected_columns() %}
        {% for source_name in expected_by_source.keys() | sort %}
            {% set relations = stripe.source_relations(source_name) %}
            {% set actual = [] %}
            {% for relation in relations %}
                {% for column in adapter.get_columns_in_relation(relation) %}
                    {% do actual.append(column.name | lower) %}
                {% endfor %}
            {% endfor %}
            {% set expected = expected_by_source[source_name] | map(attribute='name') | map('lower') | list %}
            {% set missing = expected | reject('in', actual) | list %}
            {% set extra = actual | unique | reject('in', expected) | list %}
            {% if missing or extra %}
                {% do result.update({source_name: {
                    'missing': missing,
                    'extra': extra,
                    'source_missing': relations | length == 0,
                    'source_schemas': relations | map(attribute='schema') | unique | list
                }}) %}
            {% endif %}
        {% endfor %}
        {% if flags.WHICH == 'run-operation' %}
            {{ log(tojson(result), info=True) }}
        {% endif %}
    {% endif %}
    {{ return(result) }}
{% endmacro %}
