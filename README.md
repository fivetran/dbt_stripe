[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![dbt logo and version](https://img.shields.io/static/v1?logo=dbt&label=dbt-version&message=0.20.x&color=orange)
# Stripe 

This package models Stripe data from [Fivetran's connector](https://fivetran.com/docs/applications/stripe). It uses data in the format described by [this ERD](https://fivetran.com/docs/applications/stripe#schemainformation).

This package enables you to better understand your Stripe transactions. Its main focus is to enhance the balance transaction entries with useful fields from related tables. Additionally, the metrics tables allow you to better understand your account activity over time or at a customer level. These time-based metrics are available on a daily, weekly, monthly, and quarterly level.

## Models

This package contains transformation models, designed to work simultaneously with our [Stripe source package](https://github.com/fivetran/dbt_stripe_source). A dependency on the source package is declared in this package's `packages.yml` file, so it will automatically download when you run `dbt deps`. The primary outputs of this package are described below. Intermediate models are used to create these output models.

| **model**                          | **description**                                                                                                                                                                                                                              |
|--------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [stripe__balance_transactions](https://github.com/fivetran/dbt_stripe/blob/master/models/stripe__balance_transactions.sql)    | Each record represents a change to your account balance, enriched with data about the transaction.                                                                                                                                       |
| [stripe__invoice_line_items](https://github.com/fivetran/dbt_stripe/blob/master/models/stripe__invoice_line_items.sql)      | Each record represents an invoice line item, enriched with details about the associated charge, customer, subscription, and plan.                                                                                                        |
| [stripe__subscription_details](https://github.com/fivetran/dbt_stripe/blob/master/models/stripe__subscription_details.sql)    | Each record represents a subscription, enriched with customer details and payment aggregations.                                                                                                                                          |
| [stripe__subscription_line_items](https://github.com/fivetran/dbt_stripe/blob/master/models/stripe__subscription_line_items.sql) | Each record represents a subscription invoice line item, enriched with details about the associated charge, customer, subscription, and plan. Use this table as the starting point for your company-specific churn and MRR calculations. |
| [stripe__customer_overview](https://github.com/fivetran/dbt_stripe/blob/master/models/stripe__customer_overview.sql)       | Each record represents a customer, enriched with metrics about their associated transactions.                                                                                                                                            |
| [stripe__daily_overview](https://github.com/fivetran/dbt_stripe/blob/master/models/stripe__daily_overview.sql)          | Each record represents a single day, enriched with metrics about balances, payments, refunds, payouts, and other transactions.                                                                                                           |
| [stripe__weekly_overview](https://github.com/fivetran/dbt_stripe/blob/master/models/stripe__weekly_overview.sql)         | Each record represents a single week, enriched with metrics about balances, payments, refunds, payouts, and other transactions.                                                                                                          |
| [stripe__monthly_overview](https://github.com/fivetran/dbt_stripe/blob/master/models/stripe__monthly_overview.sql)        | Each record represents a single month, enriched with metrics about balances, payments, refunds, payouts, and other transactions.                                                                                                         |
| [stripe__quarterly_overview](https://github.com/fivetran/dbt_stripe/blob/master/models/stripe__quarterly_overview.sql)      | Each record represents a single quarter, enriched with metrics about balances, payments, refunds, payouts, and other transactions.                                                                                                       |

## Installation Instructions

Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

Include in your `packages.yml`

```yaml
packages:
  - package: fivetran/stripe
    version: [">=0.4.0", "<0.5.0"]
```

## Configuration

By default, this package will look for your Stripe data in the `stripe` schema of your [target database](https://docs.getdbt.com/docs/running-a-dbt-project/using-the-command-line-interface/configure-your-profile). If this is not where your Stripe data is, please add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
  stripe_source:
    stripe_database: your_database_name
    stripe_schema: your_schema_name
```

For additional configurations for the source models, please visit the [Stripe source package](https://github.com/fivetran/dbt_stripe_source).

### Disabling Models
This package takes into consideration that not every Stripe account utilizes the `invoice`, `invoice_line_item`, `payment_method`, `payment_method_card`, `plan`, or `subscription` features, and allows you to disable the corresponding functionality. By default, all variables' values are assumed to be `true`. Add variables for only the tables you want to disable:
```yml
# dbt_project.yml

...
vars:
    using_invoices:        False  #Disable if you are not using the invoice and invoice_line_item tables
    using_payment_method:  False  #Disable if you are not using the payment_method and payment_method_card tables
    using_subscriptions:   False  #Disable if you are not using the subscription and plan tables.
```

### Changing the Build Schema
By default this package will build the Stripe staging models within a schema titled (<target_schema> + `_stg_stripe`) and the Stripe final models within a schema titled (<target_schema> + `_stripe`) in your target database. If this is not where you would like your modeled Stripe data to be written to, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
models:
  stripe:
    +schema: my_new_schema_name # leave blank for just the target_schema
  stripe_source:
    +schema: my_new_schema_name # leave blank for just the target_schema
```

*Read more about using custom schemas in dbt [here](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/using-custom-schemas).*

### Setting your timezone

This packages leaves all timestamp columns in the UTC timezone. However, there are certain instances, such in the daily overview model, that timestamps have to be converted to dates. As a result, the timezone used for the timestamp becomes relevant. 

By default, this package will use the UTC timezone when converting to date, but if you want to set the timezone to the time in your Stripe reports, add the following configuration to your `dbt_project.yml`:

```yml
# dbt_project.yml

...
vars:
  stripe_timezone: "America/New_York" # Replace with your timezone
```

### Contributions

Additional contributions to this package are very welcome! Please create issues
or open PRs against `master`. Check out 
[this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) 
on the best workflow for contributing to a package.

## Database support
This package has been tested on BigQuery, Snowflake, and Redshift.

### Resources:
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Have questions, feedback, or need help? Book a time during our office hours [using Calendly](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or email us at solutions@fivetran.com
- Find all of Fivetran's pre-built dbt packages in our [dbt hub](https://hub.getdbt.com/fivetran/)
- Learn how to orchestrate [dbt transformations with Fivetran](https://fivetran.com/docs/transformations/dbt)
- Learn more about Fivetran overall [in our docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
