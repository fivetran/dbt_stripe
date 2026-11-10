{{ config(enabled=var('stripe__using_payouts', True)) }}

{{ stripe.resolve_source_columns(table_name='payout_balance_transaction', staging_columns=stripe.get_payout_balance_transaction_columns()) }}
