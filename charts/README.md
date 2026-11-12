# Stripe boards

These dbt Charts boards query the public models built by this package through
`ref()`. Install the package in a dbt project, build its models, and generate a
manifest with `dbt parse`. Run the boards from that project with a configured
warehouse source. Query SQL declares `dialect: duckdb` for warehouse translation.

- `subscription-revenue.yml`: contracted and billed MRR by currency, the latest
  selected month, and monthly MRR movements. Requires
  `stripe__using_subscriptions: true` and `stripe__using_invoices: true`.
- `invoice-collections.yml`: invoice counts, paid share, amounts paid by invoice
  creation month, and balances by currency and status. Requires
  `stripe__using_invoices: true`.

Amounts retain the units configured by `stripe__convert_values`; the boards do
not divide amounts again or assume a currency symbol. Each currency is shown
separately. The invoice trend groups by invoice creation month, not payment date.
