
with fields as (

    {{ stripe.resolve_source_columns(table_name='customer', staging_columns=stripe.get_customer_columns()) }}
),

final as (
    
    select 
        id as customer_id,
        account_balance,
        address_city as customer_address_city,
        address_country as customer_address_country,
        address_line_1 as customer_address_line_1,
        address_line_2 as customer_address_line_2,
        address_postal_code as customer_address_postal_code,
        address_state as customer_address_state,
        balance as customer_balance,
        bank_account_id,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        currency,
        default_card_id,
        delinquent as is_delinquent,
        description,
        email,
        metadata,
        name as customer_name,
        phone,
        shipping_address_city,
        shipping_address_country,
        shipping_address_line_1,
        shipping_address_line_2,
        shipping_address_postal_code,
        shipping_address_state,
        shipping_name,
        shipping_phone,
        source_relation,
        coalesce(is_deleted, false) as is_deleted
        
        {% if var('stripe__customer_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'metadata', list_of_properties = var('stripe__customer_metadata')) }}
        {% endif %}

    from fields
    {{ livemode_predicate() }}
)

select * 
from final
