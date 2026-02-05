
with base as (

    select * 
    from {{ ref('stg_stripe__account_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_stripe__account_tmp')),
                staging_columns=get_account_columns()
            )
        }}

        {{ stripe.apply_source_relation() }}

    from base
),

final as (
    
    select 
        id as account_id,
        business_profile_mcc,
        business_profile_name,
        business_type,
        charges_enabled,
        company_address_city,
        company_address_country,
        company_address_line_1,
        company_address_line_2,
        company_address_postal_code,
        company_address_state,
        company_name,
        company_phone,
        country,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        default_currency,
        email,
        is_deleted,
        metadata,
        payouts_enabled as is_payouts_enabled,
        type as account_type,
        source_relation

        {% if var('stripe__account_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__account_metadata')) }}
        {% endif %}

    from fields
)

select *
from final
