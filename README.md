# Stripe 

This package models Stripe data from [Fivetran's connector](https://fivetran.com/docs/applications/stripe). It uses data in the format described by [this ERD](https://docs.google.com/presentation/d/1DgcGgNNcH8KPiAjaFNkvT6nEpY6hJd6DZ7ux_CdIF8A/edit).

This package enables you to better understand your Streip balance transactions. The main focus is to enhance the balance transaction entries with useful fields from related tables. Additionally, the metrics tables allow you to better understand your account activity over time or at a customer level. These time based metrics are available on a daily, weekly, monthly and quarterly level.


### Models
This package contains transformation models, designed to work simultaneously with our [Stripe source package](https://github.com/fivetran/dbt_stripe_source). A depenedency on the source package is declared in this package's packages.yml file, so it will automatically download when you run dbt deps. The primary outputs of this package are described below. Intermediate models are used to create these output models.
| **model**                  | **description**                                                                                                                                               |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| stripe\_balance\_transactions             | Each record represents a change to your account balance, enriched with data about the transaction                                             |
| stripe\_customers     | Each record represents a customer, enriched with associated data about metrics of it's purchases. |
| stripe\_daily\_metrics     | Each record represents a single day, enriched with metrics about balances, payments, refunds, payouts, and other transactions.                              |
| stripe\_weekly\_metrics    | Each record represents a single week, enriched with metrics about balances, payments, refunds, payouts, and other transactions.                               |
| stripe\_monthly\_metrics   | Each record represents a single month, enriched with metrics about balances, payments, refunds, payouts, and other transactions.                             |
| stripe\_quarterly\_metrics | Each record represents a single quarter, enriched with metrics about balances, payments, refunds, payouts, and other transactions.                           |




## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

## Configuration
The [variables](https://docs.getdbt.com/docs/using-variables) needed to configure this package are as follows:

TBD

### Contributions ###

Additional contributions to this package are very welcome! Please create issues
or open PRs against `master`. Check out 
[this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) 
on the best workflow for contributing to a package.

### Resources:
- Learn more about Fivetran [here](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices

