with balance_transaction_enhanced as (

    select *
    from {{ ref('stripe__balance_transactions')}}
    where is_current_payout_balance_transaction

)

select
    payout_id,
    case 
        when payout_is_automatic = true then payout_arrival_date_at 
        else payout_created_at
    end as effective_at,
    payout_currency as currency,
    balance_transaction_id,
    balance_transaction_amount as gross,
    balance_transaction_fee as fee,
    balance_transaction_net as net,
    balance_transaction_reporting_category as reporting_category,
    balance_transaction_description as description,
    payout_arrival_date_at as payout_expected_arrival_date,
    payout_status,
    case 
        when lower(payout_status) in ('canceled','failed') then payout_created_at
        else null
    end as payout_reversed_at,
    payout_type,
    payout_description,
    coalesce(destination_bank_account_id, destination_card_id) as payout_destination_id,
    source_relation

from balance_transaction_enhanced