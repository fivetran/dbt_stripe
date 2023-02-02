select 
	post_subscription_item_id,
	site_location as location,
	site_region as region,
	count(distinct device_id) as device_count
from {{source('dbt_netbox', 'device_subscription_item_history')}}
where post_subscription_item_id is not null 
group by 1,2,3