## Stripe MRR Weekly Subscription Logic

We were unable to validate MRR numbers for weekly subscriptions with live data, but because Stripe does allow for weekly subscriptions, that level of granularity is included in the MRR calculation logic. If you notice any issues, please open a [github issue](https://github.com/fivetran/dbt_stripe/issues) and we will work with you to solve it.

## Stripe MRR Reactivation Definition
MRR type is defined as a reactivation only after a subscription item has at least three months of history. This helps distinguish true reactivations from short-term billing gaps, proration effects, or delayed subscription starts that are common in Stripe data. A three-month threshold reflects common SaaS analytics practice and provides a conservative, stable definition of reactivation without introducing additional configuration complexity. However, we understand that this definition may not be the right one for every user of this package and we'd love to collaborate with you. Please open up a [feature request](https://github.com/fivetran/dbt_stripe/issues/new?template=feature-request.yml) if you have ideas or suggestions as to how this should be defined.
