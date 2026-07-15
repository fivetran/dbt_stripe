## MRR History Anchored to Each Subscription Item's Creation Date

The `stripe__subscription_item_mrr_report` model anchors each item's MRR timeline to that item's `created_at`, reporting MRR from when the item was added through the current month. It previously anchored to `current_period_start`, which Stripe overwrites every billing cycle, so all months before the current period were dropped.

Because `subscription_item` retains only the current state of each item, we reconstruct historical quantity from `invoice_line_item`, which records the quantity actually billed for each period. For each month, we use the quantity from the most recent invoice line whose period overlaps that month (proration adjustment lines excluded); the current month uses the live `subscription_item` quantity. This lets the report surface real `expansion` and `contraction` between months rather than back-projecting today's quantity across all history.

Because this model depends on `invoice_line_item` for historical quantity, it requires `stripe__using_invoices` (enabled by default) and does not build when that variable is disabled. Stripe generates an invoice each billing period, so gaps are not expected, but when a month has no invoice line we carry the most recent prior invoiced quantity forward rather than snapping to today's quantity (which would invent phantom changes in the gap). A month falls back to the current `subscription_item` quantity only when no earlier invoice exists (months before the first invoice). Prices are not back-filled — historical months apply the item's current price.

## MRR Timeline Uses an End-of-Month Snapshot

The `stripe__subscription_item_mrr_report` model keeps a month for an item only when the subscription is still active at month-end. We enforce this by truncating `current_period_end` to its month in the timeline's upper bound, so a month is kept only while its first day is before the start of the `current_period_end` month.

The effect is that a subscription paid through the middle of a month is not on the books at that month's end and drops out entirely. For example, a monthly subscription whose last paid period runs May 15 to June 15 keeps May (a full month) but drops June, because it has lapsed by June 30.

## Stripe Subscription and Item Start-Date Fields

We anchor to `subscription_item.created_at` because MRR is reported at the item grain. The relevant fields are not interchangeable:

- **`subscription.start_date_at`** — Stripe's authoritative subscription start, backdate-aware, but at the subscription grain.
- **`subscription.created_at`** — when the subscription object was created; usually equals `start_date`, but diverges on backdating or imports.
- **`subscription_item.created_at`** — when the item was added. Stripe allows items to be added or removed mid-cycle (add-ons, seat changes, plan upgrades) and prorates by default, so this can fall later than the subscription's start. Anchoring per item attributes MRR only to the months the item existed.

## MRR Date Spine Capped at the Current Month

The `stripe__subscription_item_mrr_report` model caps its date spine at the end of the current month, regardless of how far into the future a subscription's `current_period_end` extends.

Stripe sets `current_period_end` to a future timestamp for all active subscriptions — often months or years ahead. Without a cap, the date spine extends into that future, generating rows with $0 MRR for months that have not yet occurred. These rows are not meaningful in a historical MRR context and can inflate model size significantly for users with large subscription volumes or long billing cycles.

MRR is a measure of recognized, recurring revenue for a given month. It is a backwards-looking metric used for financial reporting, cohort analysis, and churn classification — not a forecast. Including future months conflates MRR with projected or contracted revenue, which is a different concept. Each month, once that period becomes current, a new row appears naturally if the subscription is still active.

## Stripe MRR Weekly Subscription Logic

We were unable to validate MRR numbers for weekly subscriptions with live data, but because Stripe does allow for weekly subscriptions, that level of granularity is included in the MRR calculation logic. If you notice any issues, please open a [github issue](https://github.com/fivetran/dbt_stripe/issues) and we will work with you to solve it.

## Stripe MRR Reactivation Definition
MRR type is defined as a reactivation only after a subscription item has at least three months of history. This helps distinguish true reactivations from short-term billing gaps, proration effects, or delayed subscription starts that are common in Stripe data. A three-month threshold reflects common SaaS analytics practice and provides a conservative, stable definition of reactivation without introducing additional configuration complexity. However, we understand that this definition may not be the right one for every user of this package and we'd love to collaborate with you. Please open up a [feature request](https://github.com/fivetran/dbt_stripe/issues/new?template=feature-request.yml) if you have ideas or suggestions as to how this should be defined.
