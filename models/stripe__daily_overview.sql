with final as (

    select * 
    from {{ ref('int_stripe__account_running_totals') }}
) 

select *
from final