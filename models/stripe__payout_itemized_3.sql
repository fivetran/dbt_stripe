with payout as (
    
    select
        payout_id,
        amount as payout_amount,
        arrival_date,
        is_automatic,
        balance_transaction_id,
        created_at,
        currency as payout_currency,
        description as payout_description,
        destination_bank_account_id,
        destination_card_id,
        metadata as payout_metadata,
        method,
        source_type,
        status as payout_status,
        type as payout_type
    
    from {{ var('payout') }}

), balance_transaction as (

    select
        balance_transaction_id, 
        connected_account_id,
        created_at as balance_transaction_created_at,
        available_on, 
        currency, 
        amount, 
        fee, 
        net, 
        reporting_category, 
        source as source_id, 
        status as balance_transaction_status,
        type as balance_transaction_type,
        description as balance_transaction_description

    from {{ var('balance_transaction') }}

)

select
    payout.payout_id,
    case when is_automatic 
        then payout.arrival_date 
        else created_at
    end as effective_at,
    payout.payout_currency,
    payout.balance_transaction_id,
    balance_transaction.amount as gross,
    balance_transaction.fee,
    balance_transaction.net,
    balance_transaction.reporting_category,
    balance_transaction.balance_transaction_description,
    payout.payout_status,
    payout.payout_type,
    payout.payout_description,
    coalesce(payout.destination_bank_account_id, payout.destination_card_id) as payout_destination_id

from payout

left join balance_transaction 
    on payout.balance_transaction_id = balance_transaction.balance_transaction_id