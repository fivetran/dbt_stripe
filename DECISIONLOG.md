## MRR Date Spine Capped at the Current Month

The `stripe__subscription_item_mrr_report` model caps its date spine at the end of the current month, regardless of how far into the future a subscription's `current_period_end` extends.

Stripe sets `current_period_end` to a future timestamp for all active subscriptions — often months or years ahead. Without a cap, the date spine extends into that future, generating rows with $0 MRR for months that have not yet occurred. These rows are not meaningful in a historical MRR context and can inflate model size significantly for users with large subscription volumes or long billing cycles.

MRR is a measure of recognized, recurring revenue for a given month. It is a backwards-looking metric used for financial reporting, cohort analysis, and churn classification — not a forecast. Including future months conflates MRR with projected or contracted revenue, which is a different concept. Each month, once that period becomes current, a new row appears naturally if the subscription is still active.

## Stripe MRR Weekly Subscription Logic

We were unable to validate MRR numbers for weekly subscriptions with live data, but because Stripe does allow for weekly subscriptions, that level of granularity is included in the MRR calculation logic. If you notice any issues, please open a [github issue](https://github.com/fivetran/dbt_stripe/issues) and we will work with you to solve it.

## Stripe MRR Reactivation Definition
MRR type is defined as a reactivation only after a subscription item has at least three months of history. This helps distinguish true reactivations from short-term billing gaps, proration effects, or delayed subscription starts that are common in Stripe data. A three-month threshold reflects common SaaS analytics practice and provides a conservative, stable definition of reactivation without introducing additional configuration complexity. However, we understand that this definition may not be the right one for every user of this package and we'd love to collaborate with you. Please open up a [feature request](https://github.com/fivetran/dbt_stripe/issues/new?template=feature-request.yml) if you have ideas or suggestions as to how this should be defined.
