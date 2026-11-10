{{ config(enabled=var('stripe__using_payouts', True)) }}

{{ stripe.resolve_source_columns(table_name='payout', staging_columns=stripe.get_payout_columns()) }}
