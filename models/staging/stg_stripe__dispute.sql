
with base as (

    select * 
    from {{ ref('stg_stripe__dispute_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__dispute_tmp')),
                staging_columns=get_dispute_columns()
            )
        }}

        {{ stripe.apply_source_relation() }}

    from base
),

final as (
    
    select
        id as dispute_id,
        {{ stripe.convert_values('amount', alias='dispute_amount') }},
        balance_transaction,
        charge_id,
        connected_account_id,
        cast(created as {{ dbt.type_timestamp() }}) as dispute_created_at,
        currency as dispute_currency,
        evidence_access_activity_log,
        evidence_billing_address,
        evidence_cancellation_policy,
        evidence_cancellation_policy_disclosure,
        evidence_cancellation_rebuttal,
        evidence_customer_communication,
        evidence_customer_email_address,
        evidence_customer_name,
        evidence_customer_purchase_ip,
        evidence_customer_signature,
        evidence_details_due_by,
        evidence_details_has_evidence,
        evidence_details_past_due,
        evidence_details_submission_count,
        evidence_duplicate_charge_documentation,
        evidence_duplicate_charge_explanation,
        evidence_duplicate_charge_id,
        evidence_product_description,
        evidence_receipt,
        evidence_refund_policy,
        evidence_refund_policy_disclosure,
        evidence_refund_refusal_explanation,
        evidence_service_date,
        evidence_service_documentation,
        evidence_shipping_address,
        evidence_shipping_carrier,
        evidence_shipping_date,
        evidence_shipping_documentation,
        evidence_shipping_tracking_number,
        evidence_uncategorized_file,
        evidence_uncategorized_text,
        is_charge_refundable,
        metadata as dispute_metadata,
        reason as dispute_reason,
        status as dispute_status,
        source_relation
        
        {% if var('stripe__dispute_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__dispute_metadata')) }}
        {% endif %}

    from fields
    {{ livemode_predicate() }}
)

select *
from final
