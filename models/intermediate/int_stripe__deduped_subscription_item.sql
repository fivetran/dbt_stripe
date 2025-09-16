with subscription_item as (

    select * 
    from {{ ref('stg_stripe__subscription_item') }}

)

/*
Newer Stripe connections will store current_period_start/end fields in SUBSCRIPTION_ITEM while older ones house these fields in SUBSCRIPTION_HISTORY -> grab both and coalesce
SUBSCRIPTION_ITEM allows for one-to-many relationships between subscriptions and plans, so we need to dedupe to the subscription_id level
*/

    select
        subscription_id,
        source_relation,
        min(current_period_start) as current_period_start,
        max(current_period_end) as current_period_end
        
    from subscription_item
    group by subscription_id, source_relation