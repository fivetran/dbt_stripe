{{ config(enabled=var('stripe__using_invoices', True)) }}

with fields as (

    select *
    from {{ ref('stg_stripe__invoice_line_item_tmp') }}
),

final as (
    
    select 
        id as invoice_line_item_id,
        invoice_id,
        invoice_item_id,
        {{ stripe.convert_values('amount') }},
        {{ stripe.convert_values('cast(unit_amount_excluding_tax as ' ~ dbt.type_numeric() ~ ')', alias='unit_amount_excluding_tax') }},
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
