select
i.invoice_id as balance_transaction_id,
cast(i.created_at as {{ dbt_utils.type_timestamp() }}) as created_at,
cast(i.created_at as {{ dbt_utils.type_timestamp() }}) as available_on,
i.currency,
i.amount_due as amount,
0 as fees,
i.amount_due as net,
'abine_invoice_only' as type,
'charge' as reporting_category,
i.invoice_id as source,
i.description,
i.amount_due as customer_facing_amount,
i.currency as customer_facing_currency,
cast(i.created_at as {{ dbt_utils.type_timestamp() }}) as effective_at,
c.customer_id,
c.email as receipt_email,
c.description as customer_description,
1 as customer_type,

{% if var('using_payment_method', True) %}
null as payment_method_type,
null as payment_method_brand,
null as payment_method_funding,
{% endif %}

null as charge_id,
null as payment_intent_id,
cast(i.created_at as {{ dbt_utils.type_timestamp() }}) as charge_created_at,
cast(i.created_at as {{ dbt_utils.type_timestamp() }}) as revenue_recognition_date,
i.invoice_id,
null as card_brand,
null as card_funding,
null as card_country,
null as payout_id,
null as payout_expected_arrival_date,
null as payout_status,
null as payout_type,
null as payout_description,
null as refund_reason
from {{ var('invoice') }} i
left join {{ var('customer') }} c on c.customer_id = i.customer_id
where i.charge_id is null and i.status = 'paid' and amount_due > 0 