# Stripe Transformation dbt Package ([Docs](https://fivetran.github.io/dbt_stripe/))

<p align="left">
    <a alt="License"
        href="https://github.com/fivetran/dbt_stripe/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_Core™_version->=1.3.0_,<2.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
    <a alt="Fivetran Quickstart Compatible"
        href="https://fivetran.com/docs/transformations/dbt/quickstart">
        <img src="https://img.shields.io/badge/Fivetran_Quickstart_Compatible%3F-yes-green.svg" /></a>
</p>

## What does this dbt package do?
- Produces modeled tables that leverage Stripe data from [Fivetran's connector](https://fivetran.com/docs/applications/stripe) in the format described by [this ERD](https://fivetran.com/docs/applications/stripe#schemainformation) and build off the output of our [stripe source package](https://github.com/fivetran/dbt_stripe_source).
- Enables you to better understand your Stripe transactions. The package achieves this by performing the following:
    - Enhance the balance transaction entries with useful fields from related tables. 
    - Generate a metrics tables allow you to better understand your account activity over time or at a customer level. These time-based metrics are available on a daily, weekly, monthly, and quarterly level.
- Generates a comprehensive data dictionary of your source and modeled Stripe data through the [dbt docs site](https://fivetran.github.io/dbt_stripe/).

<!--section="stripe_transformation_model"-->
The following table provides a detailed list of all tables materialized within this package by default.
> TIP: See more details about these tables in the package's [dbt docs site](https://fivetran.github.io/dbt_stripe/#!/overview?g_v=1).

| **Table**                          | **Description**                                                                                                                                                                                                                              |
|--------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [stripe__balance_transactions](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__balance_transactions)    | Each record represents a change to your account balance, enriched with data about the transaction.                                                                                                                                       |
| [stripe__invoice_details](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__invoice_details)      | Each record represents an invoice, enriched with details about the associated charge, customer, and subscription data.
| [stripe__invoice_line_item_details](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__invoice_line_item_details)      | Each record represents an invoice line item, enriched with details about the associated charge, customer, subscription, and pricing data.
| [stripe__daily_overview](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__daily_overview)      | Each record represents, per day, a summary of daily totals and rolling totals by transaction type (balances, payments, refunds, payouts, and other transactions). You may use this table to roll up into weekly, quarterly, monthly, and other time grains. You may also use this table to create a MRR report.                                                  |
| [stripe__subscription_details](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__subscription_details)    | Each record represents a subscription, enriched with customer details and payment aggregations.                                                                                                                                          |
| [stripe__customer_overview](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__customer_overview)       | Each record represents a customer, enriched with metrics about their associated transactions.  Transactions with no associated customer will have a customer description of "No associated customer".                                                                                                                                               |
| [stripe__activity_itemized_2](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__activity_itemized_2)       |  This report displays balance transactions alongside associated customer, charge, refund, fee, and invoice details, useful for Interchange Plus (IC+) pricing users.                                                                                                                                             |
| [stripe__balance_change_from_activity_itemized_3](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__balance_change_from_activity_itemized_3)       | This report functions like a bank statement for reconciling your Stripe balance, especially beneficial for treating Stripe as a bank account for accounting purposes. It offers a detailed breakdown of transactions affecting your balance.                                                                                                                                               |
| [stripe__ending_balance_reconciliation_itemized_4](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__ending_balance_reconciliation_itemized_4)       | This reports models after Stripe's payout reconciliation reports, helping match bank account payouts with related transactions. It provides details for automatic payouts and transactions that hadn't settled as of the report's end date. This report is only available for users with automatic payouts enabled and optimized for those who prefer to reconcile the transactions included in each payout as a settlement batch.                                                                                                                                               |
| [stripe__payout_itemized_3](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__payout_itemized_3)       | This report represents payouts with information on expected arrival dates and status, akin to a bank statement for reconciling your Stripe balance, particularly useful for accounting purposes.
| [stripe__line_item_enhanced](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__line_item_enhanced)       | This table is a comprehensive, denormalized analytical table that enables reporting on key revenue, subscription, customer, and product metrics from your billing platform. It’s designed to align with the schema of the `*__line_item_enhanced` table found in Stripe, Recharge, Recurly, Shopify, and Zuora, offering standardized reporting across various billing platforms. To see the kinds of insights this table can generate, explore example visualizations in the [Fivetran Billing Model Streamlit App](https://fivetran-billing-model.streamlit.app/). Visit the app for more details.  |

### Example Visualizations
Curious what these tables can do? Check out example visualizations from the [stripe__line_item_enhanced](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__line_item_enhanced) table in the [Fivetran Billing Model Streamlit App](https://fivetran-billing-model.streamlit.app/), and see how you can use these tables in your own reporting. Below is a screenshot of an example report—explore the app for more.

<p align="center">
<a href="https://fivetran-billing-model.streamlit.app/">
    <img src="https://raw.githubusercontent.com/fivetran/dbt_stripe/main/images/streamlit_example.png" alt="Streamlit Billing Model App" width="75%">
</a>
</p>

### Materialized Models
Each Quickstart transformation job run materializes 57 models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.
<!--section-end-->

## How do I use the dbt package?

### Step 1: Prerequisites
To use this dbt package, you must have the following:

- At least one Fivetran Stripe connection syncing data into your destination.
- A **BigQuery**, **Snowflake**, **Redshift**, **Databricks**, or **PostgreSQL** destination.

#### Databricks Dispatch Configuration
If you are using a Databricks destination with this package you will need to add the below (or a variation of the below) dispatch configuration within your `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages respectively.
```yml
dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```

### Step 2: Install the package
Include the following stripe package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/stripe
    version: [">=0.15.0", "<0.16.0"]
```
Do **NOT** include the `stripe_source` package in this file. The transformation package itself has a dependency on it and will install the source package as well.

### Step 3: Define database and schema variables
By default, this package runs using your destination and the `stripe` schema. If this is not where your stripe data is (for example, if your stripe schema is named `stripe_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    stripe_database: your_destination_name
    stripe_schema: your_schema_name 
```

### Step 4: Disable models for non-existent sources
This package takes into consideration that not every Stripe account utilizes the `invoice`, `invoice_line_item`, `payment_method`, `payment_method_card`, `plan`, `price`, `subscription`, or `credit_note` features, and allows you to disable the corresponding functionality. By default, all variables' values are assumed to be `true` with the exception of `credit_note`. Add variables for only the tables you want to disable or enable respectively:

```yml
# dbt_project.yml

...
vars:
    stripe__using_invoices:        False  #Disable if you are not using the invoice and invoice_line_item tables
    stripe__using_payment_method:  False  #Disable if you are not using the payment_method and payment_method_card tables
    stripe__using_subscriptions:   False  #Disable if you are not using the subscription and plan/price tables.
    stripe__using_credit_notes:    True   #Enable if you are using the credit note tables.
```
### (Optional) Step 5: Additional configurations
<details open><summary>Expand to view configurations</summary>

#### Enabling Standardized Billing Model
This package contains the `stripe__line_item_enhanced` model which constructs a comprehensive, denormalized analytical table that enables reporting on key revenue, subscription, customer, and product metrics from your billing platform. It’s designed to align with the schema of the `*__line_item_enhanced` model found in Recurly, Recharge, Stripe, Shopify, and Zuora, offering standardized reporting across various billing platforms. To see the kinds of insights this model can generate, explore example visualizations in the [Fivetran Billing Model Streamlit App](https://fivetran-billing-model.streamlit.app/). For the time being, this model is disabled by default. If you would like to enable this model you will need to adjust the `stripe__standardized_billing_model_enabled` variable to be `true` within your `dbt_project.yml`:

```yml
vars:
  stripe__standardized_billing_model_enabled: true # false by default.
```

#### Unioning Multiple Stripe Connections
If you have multiple Stripe connections you would like to use this package on simultaneously, we have added the ability to do so. Data from disparate connections will be unioned together and be passed downstream to the end models. The `source_relation` column will specify where each record comes from. To use this functionality, you will need to either set the `stripe_union_schemas` or `stripe_union_databases` variables. Please also make sure the single-source `stripe_database` and `stripe_schema` variables are removed.

```yml
# dbt_project.yml

...
config-version: 2

vars:
    stripe_union_schemas: ['stripe_us','stripe_mx'] # use this if the data is in different schemas/datasets of the same database/project
    stripe_union_databases: ['stripe_db_1','stripe_db_2'] # use this if the data is in different databases/projects but uses the same schema name
```
#### Leveraging Plan vs Price Sources

Customers using Fivetran with the newer [Stripe Price API](https://stripe.com/docs/billing/migration/migrating-prices) will have a `price` table, and possibly a `plan` table if that was used previously. Therefore to accommodate two different source tables we added logic to check if there exists a `price` table by default. If not, it will leverage the `plan` table. However if you wish to use the `plan` table instead, you may set `stripe__using_price` to `false` in your `dbt_project.yml` to override the macro.

```yml
# dbt_project.yml

...
config-version: 2

vars:
  stripe__using_price: false #  True by default. If true, will look `price ` table. If false, will look for the `plan` table. 
```

#### Leveraging Subscription Vs Subscription History Sources
For Stripe connections set up after February 09, 2022 the `subscription` table has been replaced with the new `subscription_history` table. By default this package will look for your subscription data within the `subscription_history` source table. However, if you have an older connection, then you must configure the `stripe__using_subscription_history` to `false` in order to have the package use the `subscription` source rather than the `subscription_history` table.
> **Please note that if you have `stripe__using_subscription_history` enabled then the package will filter for only active records.**
```yml
vars:
    stripe__using_subscription_history: False  # True by default. Set to False if your connection syncs the `subscription` table instead. 
```

#### Setting your timezone
This packages leaves all timestamp columns in the UTC timezone. However, there are certain instances, such in the daily overview model, that timestamps have to be converted to dates. As a result, the timezone used for the timestamp becomes relevant.  By default, this package will use the UTC timezone when converting to date, but if you want to set the timezone to the time in your Stripe reports, add the following configuration to your root `dbt_project.yml`:

```yml
vars:
  stripe_timezone: "America/New_York" # Replace with your timezone
```

#### Running on Live vs Test Customers
By default, this package will run on non-test data (`where livemode = true`) from the source Stripe tables. However, you may want to include and focus on test data when testing out the package or developing your analyses. To run on only test data, add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    stripe_source:
        stripe__using_livemode: false  # Default = true
```
#### Including sub Invoice Line Items
By default, this package will filter out any records from the `invoice_line_item` source table which include the string `sub_`. This is due to a legacy Stripe issue where `sub_` records were found to be duplicated. However, if you highly utilize these records you may wish they be included in the final output of the `stg_stripe__invoice_line_item` model. To do, so you may include the below variable configuration in your root `dbt_project.yml`:
```yml
vars:
    stripe_source:
        stripe__using_invoice_line_sub_filter: false # Default = true
```


#### Pivoting out Metadata Properties
Oftentimes you may have custom fields within your source tables that is stored as a JSON object that you wish to pass through. By leveraging the `metadata` variable, this package will pivot out fields into their own columns within the respective staging models from the `dbt_stripe_source` package. The metadata variables accept dictionaries in addition to strings.

Additionally, you may `alias` your field if you happen to be using a reserved word as a metadata field, any otherwise incompatible name, or just wish to rename your field. Below are examples of how you would add the respective fields.

The `metadata` JSON field is present within the `customer`, `charge`, `card`, `invoice`, `invoice_line_item`, `payment_intent`, `payment_method`, `payout`, `plan`, `price`, `refund`, and `subscription` source tables. To pivot these fields out and include in the respective downstream staging model, add the relevant variable(s) to your root `dbt_project.yml` file like below.

```yml
vars: 
  stripe__account_metadata:
    - name: metadata_field
    - name: another_metadata_field
    - name: and_another_metadata_field
  stripe__charge_metadata:
    - name: metadata_field_1
  stripe__card_metadata:
    - name: metadata_field_10
  stripe__customer_metadata:
    - name: metadata_field_6
      alias: metadata_field_six
  stripe__invoice_metadata: 
    - name: metadata_field_2
  stripe__invoice_line_item_metadata: 
    - name: metadata_field_20
  stripe__payment_intent_metadata:
    - name: incompatible.field
      alias: rename_incompatible_field
  stripe__payment_method_metadata:
    - name: field_is_reserved_word
      alias: field_is_reserved_word_xyz
  stripe__payout_metadata:
    - name: 123
      alias: one_two_three
  stripe__price_plan_metadata: ## Used for both Price and Plan sources
    - name: rename_price
      alias: renamed_field_price
  stripe__refund_metadata:
    - name: metadata_field_3
  stripe__subscription_metadata:
    - name: 567
      alias: five_six_seven

```

Alternatively, if you only have strings in your JSON object, the metadata variable accepts the following configuration as well.

```yml
vars:
    stripe__subscription_metadata: ['the', 'list', 'of', 'property', 'fields'] # Note: this is case-SENSITIVE and must match the casing of the property as it appears in the JSON
```

#### Enabling Cent to Dollar Conversion

Amount-based fields, such as `amount` and `net`, are typically displayed in the smallest denomination (e.g., cents for USD). By default, amount-based fields will be in this raw form. However, some currencies use major and minor units (for example, cents and dollars when using USD). In these cases, it may be useful to divide the amounts by 100, converting amounts to major units (dollars for USD). To enable the division, configure the `stripe__convert_values` to `true` in your project.yml: 

```yml
vars:
    stripe__convert_values: true  # default is false 
```

If you are working in a currency that does not differentiate between minor and major units, such as JPY or KRW, it may make more sense to keep the amount-based fields in raw form and therefore the package can be ran without configuration. As `stripe__convert_values` is disabled by default, these fields will not be impacted.

#### Change the build schema
By default, this package builds the stripe staging models within a schema titled (`<target_schema>` + `_stg_stripe`) in your destination. If this is not where you would like your stripe staging data to be written to, add the following configuration to your root `dbt_project.yml` file:

```yml
models:
    stripe_source:
      +schema: my_new_schema_name # leave blank for just the target_schema
```
    
#### Change the source table references
If an individual source table has a different name than the package expects, add the table name as it appears in your destination to the respective variable:
> IMPORTANT: See this project's [`dbt_project.yml`](https://github.com/fivetran/dbt_stripe_source/blob/main/dbt_project.yml) variable declarations to see the expected names.
    
```yml
vars:
    stripe_<default_source_table_name>_identifier: your_table_name 
```

</details>

### (Optional) Step 6: Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for details</summary>
<br>
    
Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt#setupguide).
</details>

## Does this package have dependencies?
This dbt package is dependent on the following dbt packages. These dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.
    
```yml
packages:
    - package: fivetran/stripe_source
      version: [">=0.12.0", "<0.13.0"]

    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]

    - package: dbt-labs/spark_utils
      version: [">=0.3.0", "<0.4.0"]
```
## How is this package maintained and can I contribute?
### Package Maintenance
The Fivetran team maintaining this package _only_ maintains the latest version of the package. We highly recommend you stay consistent with the [latest version](https://hub.getdbt.com/fivetran/stripe/latest/) of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_stripe/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Check out [this dbt Discourse article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package.

## Are there any resources available?
- If you have questions or want to reach out for help, see the [GitHub Issue](https://github.com/fivetran/dbt_stripe/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
