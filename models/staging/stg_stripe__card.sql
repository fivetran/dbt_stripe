
with fields as (

    {{ stripe.resolve_source_columns(table_name='card', staging_columns=stripe.get_card_columns()) }}
),

final as (
    
    select 
        id as card_id,
        account_id,
        address_city as card_address_city,
        address_country as card_address_country,
        address_line_1 as card_address_line_1,
        address_line_2 as card_address_line_2,
        address_state as card_address_state,
        address_zip as card_address_postal_code,
        wallet_type,
        brand,
        country,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        customer_id,
        name as card_name,
        recipient,
        funding,
        source_relation
        
        {% if var('stripe__card_metadata',[]) %}
        , {{ fivetran_utils.pivot_json_extract(string = 'card_metadata', list_of_properties = var('stripe__card_metadata')) }}
        {% endif %}

        {{ fivetran_utils.fill_pass_through_columns('card_pass_through_columns') }}

    from fields
)

select * 
from final
