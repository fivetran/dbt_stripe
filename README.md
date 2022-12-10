<p align="center">
    <a alt="License"
        href="https://github.com/fivetran/dbt_stripe/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_Core™_version->=1.3.0_,<2.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
</p>

# Stripe Transformation dbt Package ([Docs](https://fivetran.github.io/dbt_stripe/))
# 📣 What does this dbt package do?
- Produces modeled tables that leverage Stripe data from [Fivetran's connector](https://fivetran.com/docs/applications/stripe) in the format described by [this ERD](https://fivetran.com/docs/applications/stripe#schemainformation) and build off the output of our [stripe source package](https://github.com/fivetran/dbt_stripe_source).
- Enables you to better understand your Stripe transactions. The package achieves this by performing the following: 
    - Enhance the balance transaction entries with useful fields from related tables. 
    - Generate a metrics tables allow you to better understand your account activity over time or at a customer level. These time-based metrics are available on a daily, weekly, monthly, and quarterly level.
- Generates a comprehensive data dictionary of your source and modeled Stripe data through the [dbt docs site](https://fivetran.github.io/dbt_stripe/).

The following table provides a detailed list of all models materialized within this package by default. 
> TIP: See more details about these models in the package's [dbt docs site](https://fivetran.github.io/dbt_stripe/#!/overview?g_v=1).

| **model**                          | **description**                                                                                                                                                                                                                              |
|--------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [stripe__balance_transactions](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__balance_transactions)    | Each record represents a change to your account balance, enriched with data about the transaction.                                                                                                                                       |
| [stripe__invoice_line_items](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__invoice_line_items)      | Each record represents an invoice line item, enriched with details about the associated charge, customer, subscription, and plan.                                                                                                        |
| [stripe__subscription_details](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__subscription_details)    | Each record represents a subscription, enriched with customer details and payment aggregations.                                                                                                                                          |
| [stripe__subscription_line_items](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__subscription_line_items) | Each record represents a subscription invoice line item, enriched with details about the associated charge, customer, subscription, and plan. Use this table as the starting point for your company-specific churn and MRR calculations. |
| [stripe__customer_overview](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__customer_overview)       | Each record represents a customer, enriched with metrics about their associated transactions.  Transactions with no associated customer will have a customer description of "No associated customer".                                                                                                                                          |
| [stripe__daily_overview](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__daily_overview)          | Each record represents a single day, enriched with metrics about balances, payments, refunds, payouts, and other transactions.                                                                                                           |
| [stripe__weekly_overview](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__weekly_overview)         | Each record represents a single week, enriched with metrics about balances, payments, refunds, payouts, and other transactions.                                                                                                          |
| [stripe__monthly_overview](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__monthly_overview)        | Each record represents a single month, enriched with metrics about balances, payments, refunds, payouts, and other transactions.                                                                                                         |
| [stripe__quarterly_overview](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__quarterly_overview)      | Each record represents a single quarter, enriched with metrics about balances, payments, refunds, payouts, and other transactions.                                                                                                       |

# 🎯 How do I use the dbt package?

## Step 1: Prerequisites
To use this dbt package, you must have the following:

- At least one Fivetran Stripe connector syncing data into your destination.
- A **BigQuery**, **Snowflake**, **Redshift**, **Databricks**, or **PostgreSQL** destination.

### Databricks Dispatch Configuration
If you are using a Databricks destination with this package you will need to add the below (or a variation of the below) dispatch configuration within your `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages respectively.
```yml
dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```

## Step 2: Install the package
Include the following stripe package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/stripe
    version: [">=0.8.0", "<0.9.0"]

```
## Step 3: Define database and schema variables
By default, this package runs using your destination and the `stripe` schema. If this is not where your stripe data is (for example, if your stripe schema is named `stripe_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    stripe_database: your_destination_name
    stripe_schema: your_schema_name 
```

## Step 4: Disable models for non-existent sources
This package takes into consideration that not every Stripe account utilizes the `invoice`, `invoice_line_item`, `payment_method`, `payment_method_card`, `plan`, or `subscription` features, and allows you to disable the corresponding functionality. By default, all variables' values are assumed to be `true`. Add variables for only the tables you want to disable within your root `dbt_project.yml`:
```yml
vars:
    stripe__using_invoices:        False  #Disable if you are not using the invoice and invoice_line_item tables
    stripe__using_payment_method:  False  #Disable if you are not using the payment_method and payment_method_card tables
    stripe__using_subscriptions:   False  #Disable if you are not using the subscription and plan tables.
```
## Step 5: Leveraging Subscription Vs Subscription History Sources
For Stripe connectors set up after February 09, 2022 the `subscription` table has been replaced with the new `subscription_history` table. By default this package will look for your subscription data within the `subscription` source table. However, if you have a newer connector then you must leverage the `stripe__subscription_history` to have the package use the `subscription_history` source rather than the `subscription` table.
> **Please note that if you have `stripe__subscription_history` enabled then the package will filter for only active records.**
```yml
vars:
    stripe__subscription_history: True  # False by default. Set to True if your connector syncs the `subscription_history` table. 
```
## (Optional) Step 6: Additional configurations
<details><summary>Expand for configurations</summary>

### Setting your timezone
This packages leaves all timestamp columns in the UTC timezone. However, there are certain instances, such in the daily overview model, that timestamps have to be converted to dates. As a result, the timezone used for the timestamp becomes relevant.  By default, this package will use the UTC timezone when converting to date, but if you want to set the timezone to the time in your Stripe reports, add the following configuration to your root `dbt_project.yml`:

```yml
vars:
  stripe_timezone: "America/New_York" # Replace with your timezone
```

### Running on Live vs Test Customers
By default, this package will run on non-test data (`where livemode = true`) from the source Stripe tables. However, you may want to include and focus on test data when testing out the package or developing your analyses. To run on only test data, add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    stripe_source:
        using_livemode: false  # Default = true
```
### Including sub Invoice Line Items
By default, this package will filter out any records from the `invoice_line_item` source table which include the string `sub_`. This is due to a legacy Stripe issue where `sub_` records were found to be duplicated. However, if you highly utilize these records you may wish they be included in the final output of the `stg_stripe__invoice_line_item` model. To do, so you may include the below variable configuration in your root `dbt_project.yml`:
```yml
vars:
    stripe_source:
        using_invoice_line_sub_filter: false # Default = true
```


### Pivoting out Metadata Properties
Oftentimes you may have custom fields within your source tables that is stored as a JSON object that you wish to pass through. By leveraging the `metadata` variable, this package pivot out fields into their own columns. The metadata variables accept dictionaries in addition to strings.

Additionally, if you happen to be using a reserved word as a metadata field, any otherwise incompatible name, or just wish to rename your field, Below are examples of how you would add the respective fields.

The `metadata` JSON field is present within the `customer`, `charge`, `invoice`, `payment_intent`, `payment_method`, `payout`, `plan`, `refund`, and `subscription` source tables. To pivot these fields out and include in the respective downstream staging model, add the respective variable(s) to your root `dbt_project.yml` file like below.

```yml
vars: 
  stripe__charge_metadata:
    - name: metadata_field_1
  stripe__invoice_metadata: 
    - name: metadata_field_2
  stripe__payment_intent_metadata:
    - name: incompatible.field
      alias: rename_incompatible_field
  stripe__payment_method_metadata:
    - name: field_is_reserved_word
      alias: field_is_reserved_word_xyz
  stripe__payout_metadata:
    - name: 123
      alias: one_two_three
  stripe__plan_metadata:
    - name: rename
    - alias: renamed_field
  stripe__refund_metadata:
    - name: metadata_field_3
    - name: metadata_field_4
  stripe__subscription_metadata:
    - name: metadata_field_5
  stripe__customer_metadata:
    - name: metadata_field_6

```

Alternatively, if you only have strings in your JSON object, the metadata variable accepts the following configuration as well. 

```yml
vars:
    stripe__plan_metadata: ['the', 'list', 'of', 'property', 'fields'] # Note: this is case-SENSITIVE and must match the casing of the property as it appears in the JSON
```

### Change the build schema
By default, this package builds the stripe staging models within a schema titled (`<target_schema>` + `_stg_stripe`) in your destination. If this is not where you would like your stripe staging data to be written to, add the following configuration to your root `dbt_project.yml` file:

```yml
models:
    stripe_source:
      +schema: my_new_schema_name # leave blank for just the target_schema
```
    
### Change the source table references
If an individual source table has a different name than the package expects, add the table name as it appears in your destination to the respective variable:
> IMPORTANT: See this project's [`dbt_project.yml`](https://github.com/fivetran/dbt_stripe_source/blob/main/dbt_project.yml) variable declarations to see the expected names.
    
```yml
vars:
    stripe_<default_source_table_name>_identifier: your_table_name 
```

</details>

## (Optional) Step 7: Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for details</summary>
<br>
    
Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt#setupguide).
</details>

# 🔍 Does this package have dependencies?
This dbt package is dependent on the following dbt packages. Please be aware that these dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.
    
```yml
packages:
    - package: fivetran/stripe_source
      version: [">=0.8.0", "<0.9.0"]

    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]
```
# 🙌 How is this package maintained and can I contribute?
## Package Maintenance
The Fivetran team maintaining this package _only_ maintains the latest version of the package. We highly recommend you stay consistent with the [latest version](https://hub.getdbt.com/fivetran/stripe/latest/) of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_stripe/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

## Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions! 

We highly encourage and welcome contributions to this package. Check out [this dbt Discourse article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package!

# 🏪 Are there any resources available?
- If you have questions or want to reach out for help, please refer to the [GitHub Issue](https://github.com/fivetran/dbt_stripe/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
- Have questions or want to just say hi? Book a time during our office hours [on Calendly](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or email us at solutions@fivetran.com.
