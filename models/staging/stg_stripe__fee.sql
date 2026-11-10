
with fields as (

    {{ stripe.resolve_source_columns(table_name='fee', staging_columns=stripe.get_fee_columns()) }}
),

final as (
    
    select 
        balance_transaction_id,
        index,
        {{ stripe.convert_values('amount') }},
        application,
        currency,
        description,
        type,
        source_relation

    from fields
)

select * 
from final
