with payout_enhanced as (

    select *
    from {{ ref('int_stripe__payout_enhanced')}}

)

select
    payout_id,
    case 
        when is_automatic 
        then payout_arrival_date 
        else payout_created_at
    end as effective_at,
    payout_currency as currency,
    balance_transaction_id,
    balance_transaction_amount as gross,
    balance_transaction_fee,
    balance_transaction_net,
    reporting_category,
    balance_transaction_description,
    payout_status,
    case 
        when lower(payout_status) in ('canceled','failed') then payout_created_at
        else null
    end as payout_reversed_at,
    payout_type,
    balance_transaction_description as description,
    coalesce(destination_bank_account_id, destination_card_id) as payout_destination_id,
    source_relation

from payout_enhanced