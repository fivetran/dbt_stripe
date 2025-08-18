{{ config(enabled=var('stripe__using_invoices', True)) }}

with base as (

    select * 
    from {{ ref('stg_stripe__invoice_line_item_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__invoice_line_item_tmp')),
                staging_columns=get_invoice_line_item_columns()
            )
        }}

        {{ fivetran_utils.source_relation(
            union_schema_variable='stripe_union_schemas',
            union_database_variable='stripe_union_databases')
        }}
        
    from base
),

final as (
    
    select 
        id as invoice_line_item_id,
        invoice_id,
        invoice_item_id,
        {{ stripe.convert_values('amount') }},
        currency,
        description,
        discountable as is_discountable,
        plan_id,
        price_id,
        proration,
        quantity,
        subscription_id,
        subscription_item_id,
        type,
        unique_id as unique_invoice_line_item_id,
        period_start,
        period_end,
        source_relation
        
        {% if var('stripe__invoice_line_item_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__invoice_line_item_metadata')) }}
        {% endif %}

    from fields
    {{ livemode_predicate() }}

    {% if var('stripe__using_invoice_line_sub_filter', true) %}
    and id not like 'sub%' -- ids starting with 'sub' are temporary and are replaced by permanent ids starting with 'sli' 
    {% endif %}

)

select * 
from final
