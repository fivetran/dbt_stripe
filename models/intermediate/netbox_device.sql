with devices as (
    select
        d.id as device_id,
        json_extract_path_text(d.custom_field_data, 'subscription_item_id') as subscription_item_id,
        d.site_id,
        rl.location_name as location,
        rl.region_name as region,
        d.created
    from
        {{source('ft_netbox_public', 'dcim_device')}} d
           left join {{source('dbt_netbox', 'regions_locations')}} rl on d.site_id = rl.location_id)
select 
    subscription_item_id,
    location,
    region,
    count(distinct device_id) as device_count
from devices
group by 1,2,3