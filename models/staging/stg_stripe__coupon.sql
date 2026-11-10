{{ config(enabled=var('stripe__using_coupons', True)) }}

with fields as (

    {{ stripe.resolve_source_columns(table_name='coupon', staging_columns=stripe.get_coupon_columns()) }}
),

final as (
    
    select 
        id as coupon_id,
        name as coupon_name,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        cast(redeem_by as {{ dbt.type_timestamp() }}) as redeem_by,
        duration,
        duration_in_months,
        {{ stripe.convert_values('amount_off') }}, 
        percent_off,
        currency,
        metadata,
        max_redemptions,
        times_redeemed,
        valid,
        source_relation

        {% if var('stripe__coupon_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__coupon_metadata')) }}
        {% endif %}
        
    from fields

    {{ livemode_predicate() }}
)

select * 
from final