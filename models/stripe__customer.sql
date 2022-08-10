with a as 
(
select
	id as customer_id,
	account_balance,
	created as created_at,
	currency,
	default_card_id,
	delinquent as is_delinquent,
	description,
	email,
	shipping_address_city,
	shipping_address_country,
	shipping_address_line_1,
	shipping_address_line_2,
	shipping_address_postal_code,
	shipping_address_state,
	shipping_name,
	shipping_phone,
	stripe_account,
	case
		when id in ('cus_Ejb5kfPhTXsQbM' , 'cus_FXjNrwHZASUoVt') then 1
		else row_number() over (partition by id
	order by
		stripe_account desc)
	end as rn
from
	{{ source('dbt_stripe_account_src', 'customer') }}
except
select
	id as customer_id,
	account_balance,
	created as created_at,
	currency,
	default_card_id,
	delinquent as is_delinquent,
	description,
	email,
	shipping_address_city,
	shipping_address_country,
	shipping_address_line_1,
	shipping_address_line_2,
	shipping_address_postal_code,
	shipping_address_state,
	shipping_name,
	shipping_phone,
	stripe_account,
	1 as rn
from
	{{ source('dbt_stripe_account_src', 'customer') }}
where
	id in ('cus_Ejb5kfPhTXsQbM' , 'cus_FXjNrwHZASUoVt')
	and stripe_account = 'us')

select *
from a 
where rn = 1