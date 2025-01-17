# dbt_stripe v0.16.0

## Breaking Change
- The aggregated amount-based fields in `stripe__daily_overview` and `stripe__customer_overview` now reflect the raw smallest units (e.g., cents), following Stripe's raw data, instead of converted dollar amounts. This change standardizes values across all models.  

  **Impact**: Customers using these models should note that the values will appear inflated compared to the previous dollar-based representation.  

- Important to note:  
  - The cent-to-dollar conversion has been moved upstream and is now controlled by a new variable: `stripe__convert_values` which is disabled by default.  
  - To enable the conversion and divide all amount-based fields by 100, set `stripe__convert_values` to `True` in your `project.yml`.  
  - See below for more context behind these changes and for detailed setup instructions, see the [README](https://github.com/fivetran/dbt_stripe?tab=readme-ov-file#enabling-cent-to-dollar-conversion).  

## Feature Update: Optional Conversion to Major Units
- **Background**:  Stripe provides amount-based fields (e.g., `amount`, `net`, `fee`) in the smallest denomination. For currencies with minor and major units (e.g., USD), 100 represents 100 cents (1 USD). For currencies without minor units (e.g., JPY), 100 represents 100 JPY.  

- This PR introduces a variable `stripe__convert_values` (disabled by default) upstream in the staging models which allows users the option to divide all amount-based fields by 100.

- If your data is using a currency with major and minor units, it may be useful to enable this variable if you wish to divide amounts by 100 and therefore convert values into major units. For information on how to do so, refer to the [README]((https://github.com/fivetran/dbt_stripe?tab=readme-ov-file#enabling-cent-to-dollar-conversion)) on enabling the `stripe__convert_values` variable.
  - Examples of currencies using minor units (in which enabling `stripe__convert_values` may be useful) include USD (100 = 1 USD), EUR (100 = 1 Euro), and CAD (100 = 1 CAD).  

- If your Stripe data is *not* using a currency involving minor units, it may make more sense to retain the amount-based fields as raw smallest units by leaving `stripe__convert_values` disabled.
  - Examples of currencies NOT using minor units include JPY (100 = 100 JPY), IDR (100 = 100 IDR), KRW (100 = 100 KRW).


## Notes
- Currently this package does not support multiple currencies, but we have created a [feature request to support multiple currencies](https://github.com/fivetran/dbt_stripe/issues/102) where you are welcome to provide feedback or contribute to the discussion.

## Documentation
- Updated the descriptions for all amount-based fields to specify the grain of the values and add information about the `stripe__convert_values` variable.
- Added Quickstart model counts to README. ([#103](https://github.com/fivetran/dbt_stripe/pull/103))
- Corrected references to connectors and connections in the README. ([#103](https://github.com/fivetran/dbt_stripe/pull/103))

## Under the Hood
- Updated the `run_models.sh` script to test for when `stripe__convert_values` is set to True.
- Added a consistency test for `stripe__customer_overview`.

# dbt_stripe v0.15.1

## Bug Fixes
- Updated the logic in `stripe__line_item_enhanced` to properly bring in refund data by adjusting the joins on balance transactions, refunds and charges. 
  - Since charges and refunds are both types of balance transactions, included an additional join between refunds and balance transactions to bring in refunds at the same level as charges. 
    - Updated balance transactions join on `connected_account_id` and `source_relation` to look at both charge and refund balance transactions.
  - Fixed `fee_amount` logic to sum together charge and refund amounts.
    - Coalesced `fee_amount` with zero for invoice-only (non-header) rows and updated downstream summing logic accordingly. 
  - Updated `transaction_type` logic to not only bring in `charge`, but also return `charge + refund` if the balance transaction has a charge and a refund associated with it, or `payment intent + refund` if the refund balance transaction is not yet tied to a charge. 

## Under the Hood
- Modified the consistency tests to better compare differences between production and development rows.

# dbt_stripe v0.15.0

## Breaking Changes
- Updated `stripe__balance_transactions` to correctly handle multiple disputes on the same transaction:
  - Adjusted [`customer_facing_amount`](https://github.com/fivetran/dbt_stripe/blob/main/models/stripe__balance_transactions.sql#L139-L144) to reflect the `dispute_amount` of the *latest* dispute (if the transaction is not a charge or refund and is associated with any disputes) ([PR #92](https://github.com/fivetran/dbt_stripe/pull/92)).
  - Added the following the dispute-related columns ([PR #92](https://github.com/fivetran/dbt_stripe/pull/92)):
    - `latest_dispute_amount_won`: Latest disputed amount that was won in favor of the merchant.
    - `latest_dispute_amount_lost`: Latest disputed amount that was lost and returned to the customer.
    - `latest_dispute_amount_under_review`: Latest disputed amount that is currently under review by the bank.
    - `latest_dispute_amount_needs_response`: Latest disputed amount that currently needs a response (the dispute has been filed but the merchant has not yet responded with evidence).
    - `latest_dispute_amount_warning_closed`: Latest disputed amount that is currently of status `warning_under_closed` (early fraud warning being closed due to no formal dispute).
    - `latest_dispute_amount_warning_under_review`: Latest disputed amount that is currently of status `warning_under_review` (card issuer suspects possible fraud but hasn't yet escalated the situation to a full dispute).
    - `latest_dispute_amount_warning_needs_response`: Latest disputed amount that is currently of status `warning_needs_response` (early fraud warning has been escalated into formal dispute and/or card issuer has requested more information).
    - `dispute_count`: Count of disputes raised against this transaction. If > 1, join in `dispute` data for additional information on each dispute.
  - Adjusted the `dispute_id` and `dispute_reason` fields to aggregate together data from multiple disputes if present. They have been renamed to `dispute_ids` and `dispute_reasons` in the following models ([PR #88](https://github.com/fivetran/dbt_stripe/pull/88)):
    - `stripe__balance_transactions`
    - `stripe__activity_itemized_2`
    - `stripe__balance_change_from_activity_itemized_3`
    - `stripe__ending_balance_reconciliation_itemized_4`

## Under the Hood
- Updated `dispute` seed data to test the above changes ([PR #92](https://github.com/fivetran/dbt_stripe/pull/92)).
- Added additional validation tests on the affected models from above ([PR #92](https://github.com/fivetran/dbt_stripe/pull/92)).

## Contributors
- [@bramrodenburg](https://github.com/bramrodenburg) ([PR #88](https://github.com/fivetran/dbt_stripe/pull/88))
- [@jsnorthrup](https://github.com/jsnorthrup)

# dbt_stripe v0.14.1

[PR #89](https://github.com/fivetran/dbt_stripe/pull/89) includes the following updates:

## Bug Fixes
- Addressed a potential `Divide by 0` error in calculating `unit_amount` in the `stripe__line_item_enhanced` model. Now, if the denominator `invoice_line_item.quantity` is 0, `unit_amount` will also be 0.

## Under the Hood
- Expanded the `consistency_line_item_enhanced_count` test to also validate potential changes to `unit_amount` sums.
- Adjusted the `invoice_line_item` seed data to include cases where `quantity` = 0 in order to test the above bug fix.

# dbt_stripe v0.14.0
[PR #82](https://github.com/fivetran/dbt_stripe/pull/82) includes the following updates:

## Feature Updates
- Addition of the `stripe__line_item_enhanced` model. This model constructs a comprehensive, denormalized analytical table that enables reporting on key revenue, subscription, customer, and product metrics from your billing platform. It’s designed to align with the schema of the `*__line_item_enhanced` model found in Stripe, Recharge, Recurly, Shopify, and Zuora, offering standardized reporting across various billing platforms. To see the kinds of insights this model can generate, explore example visualizations in the [Fivetran Billing Model Streamlit App](https://fivetran-billing-model.streamlit.app/). Visit the app for more details.
  - This model is currently disabled by default. You may enable it by setting the `stripe__standardized_billing_model_enabled` as `true` in your `dbt_project.yml`.

## Relevant Upstream Updates ([dbt_stripe_source v0.12.0](https://github.com/fivetran/dbt_stripe_source/releases/tag/v0.12.0))
- Addition of the following new staging models and accompanying upstream references:
  - `stg_stripe__discount` (required for downstream `dbt_stripe` model transformations)
  - `stg_stripe__product` (enabled by default, but can be disabled by setting the `stripe__using_subscriptions` variable to `false`)

## Under the Hood
- Added consistency test within integration_tests for the `stripe__line_item_enhanced` model.
- Updated the `quickstart.yml` to include the `product` source table as a requirement for the `stripe__using_subscriptions` variable.

# dbt_stripe v0.13.0
[PR #78](https://github.com/fivetran/dbt_stripe/pull/78) includes the following updates:

## 🚨 Breaking Changes 🚨
- Renamed folder `stripe_reports` to `stripe_financial_reports` to be more descriptive of the contents.
  - ⚠️ If you are using folder names to scope out configs, runs, etc., you will need to update the folder name.

## Bug fixes
- Updated model `int_stripe__date_spine` to accommodate cases when model `stripe__balance_transactions` has no records. 
  - Previously, the date spine relied on `stripe__balance_transactions` to set date bounds, which caused errors if empty. Now, the model defaults to a one-month range in such cases.

## Under the hood
- Updated structure of model `int_stripe__date_spine` for improved performance and maintainability.

# dbt_stripe v0.12.0
[PR #75](https://github.com/fivetran/dbt_stripe/pull/75) includes the following updates:

## 🚨 Breaking Changes 🚨
- No longer filters out deleted customers in `stripe__customer_overview`.
  - Persists `is_deleted` field to differentiate between deleted and active customers.
  - Note that this is a 🚨 breaking change 🚨, as previously filtered-out records will appear in `stripe__customer_overview`.

## Feature Updates
- Adds the `phone` column to `stripe__customer_overview`. 

## Under the Hood
- Included auto-releaser GitHub Actions workflow to automate future releases.
- Updated the maintainer PR template to resemble the most up to date format.

# dbt_stripe v0.11.0

[PR #69](https://github.com/fivetran/dbt_stripe/pull/69) contains the following updates:

## 🚨 Breaking Changes 🚨

  - Prefixed the following fields based on their corresponding upstream source to maintain clarity:

| **Previous Name**                          | **New Name**                                                                                                                                                                                                                             |
|--------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| created_at | balance_transaction_created_at
| available_on | balance_transaction_available_on
| currency | balance_transaction_currency
| amount | balance_transaction_amount
| fee | balance_transaction_fee
| net | balance_transaction_net
| type | balance_transaction_type
| source | balance_transaction_source_id
| reporting_category | balance_transaction_reporting_category
| description | balance_transaction_description

## Updates:
- Introduced the following new models, named after the Stripe reports that they follow. These models help reproduce reports available in the [Stripe Reporting API](https://stripe.com/docs/reports/report-types). The reports introduced in this update include:
  - stripe__activity_itemized_2
  - stripe__balance_change_from_activity_itemized_3
  - stripe__ending_balance_reconciliation_itemized_4
  - stripe__payout_itemized_3

- Updated the [`stripe__balance_transactions`](https://github.com/fivetran/dbt_stripe/blob/main/models/stripe__balance_transactions.sql) with the following changes:
  - `reporting_category` has been updated to pull directly from the titular column. If no `reporting_category` exists, it then falls to sort based on balance transaction  `type` in accordance to the Stripe [documentation](https://stripe.com/docs/reports/reporting-categories).
  - Added the following fields:
    - dispute fields
    - transfer fields
    - additional payout fields
    - additional customer fields
    - additional card fields
    - additional charge fields
    - additional invoice fields
  - Updated `customer_facing_amount` to include for refunds and disputes as well
  - Updated `charge_id` to charge, refund, then dispute objects consecutively



## Under the Hood:

- Incorporated the new `fivetran_utils.drop_schemas_automation` macro into the end of each Buildkite integration test job.
- Updated the pull request [templates](/.github).

# dbt_stripe v0.10.1
[PR #61](https://github.com/fivetran/dbt_stripe/pull/61) contains the following changes:
## Documentation Updates
- Updated the Metadata pivot documentation to be more clear that these variables only affect the `dbt_stripe_source` staging models.
- Added reference to the new `stripe__card_metadata` and `stripe__invoice_line_item_metadata` metadata variables that are available in the latest source package update.

## Under the Hood
- Updated the `card` and `invoice_line_item` seed files to be consistent with the source package versions. Specifically to include the metadata fields.
- Added a new BuildKite run statement to test a few of the metadata variables.

## Upstream Changes
- See the source package [CHANGELOG](https://github.com/fivetran/dbt_stripe_source/blob/main/CHANGELOG.md) for updates made to the staging layer in dbt_stripe_source `v0.9.1`.

# dbt_stripe v0.10.0
[#60](https://github.com/fivetran/dbt_stripe/pull/60) includes the following changes:
## 🚨 Breaking Changes 🚨:
- Unwrapped `total_*` fields from the for loop in `stripe__daily_overview` to reduce compute required for previous for-loops 
- Add `account_id` in `int_stripe__account_rolling_totals` for use as part of the join in the case where more than 1 `account_id` exists.

## Under the Hood
- Intermediate model materializations have changed from ephemeral to table to reduce the compute required for the complexity of calculations. 

# dbt_stripe v0.9.0

[#56](https://github.com/fivetran/dbt_stripe/pull/56) includes the following changes:
## 🚨 Breaking Changes 🚨:
- `stripe__subscription_line_items` has been removed. To recreate it, simply filter `stripe__invoice_line_items` for where `subscription_id` is not null.
- The `stripe__weekly_overview`, `stripe__quarterly_overview`, and `stripe__monthly_overview` models have been removed as they can be recreated directly from the `stripe__daily_overview` by rolling up the date grain.
- The `stripe__invoice_line_item` and `stripe__subscription_line_items` have been renamed to `stripe__invoice_line_item_details` and `stripe__subscription_details`.
- Following the addition of the new `pricing` source table which may replace the `plan` table depending on whether you migrated to the Price API ([Stripe doc here.](https://stripe.com/docs/billing/migration/migrating-prices)), the following columns in `stripe__invoice_line_items` have been updated. This package will draw the respective columns from the `price` object by default if it exists. However, if you still have and wish to keep using `plan`, you can set `stripe__using_price` to False. For more please see the [README](https://github.com/fivetran/dbt_stripe#leveraging-plan-vs-price-sources)

| **Previous Name**                          | **New Name**                                                                                                                                                                                                                            |
|--------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| plan_is_active    | price_plan_is_active
| plan_amount    | price_plan_amount
| plan_interval    | price_plan_interval
| plan_interval_count    | price_plan_interval_count
| plan_nickname    | price_plan_nickname
| plan_product_id    | price_plan_product_id                                                                                                       |

- In addition, `stripe__plan_metadata` variable has been renamed to `stripe__price_plan_metadata`

- Stripe connectors set up after February 09, 2022 will use the subscription_history table, as they will no longer be syncing the subscription table. This package uses `subscription_history` by default if it exists. However, if you still have the `subscription` table and wish to use it instead, then set the `stripe__using_subscription_history` to False.

- Variables have been prefixed with `stripe__` so they can be used globally.

| **Previous Name**                          | **New Name**                                                                                                                                                                                                                             |
|--------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| using_invoices    | stripe__using_invoices
| using_credit_notes | stripe__using_credit_notes
| using_payment_method | stripe__using_payment_method
| using_livemode | stripe__using_livemode
| using_invoice_line_sub_filter | stripe__using_invoice_line_sub_filter
| using_subscriptions | stripe__using_subscriptions
| using_subscription_history | stripe__using_subscription_history
| using_price | stripe__using_price

- In the `stripe__subscription_details` model, `start_date` has been updated to `start_date_at` to follow our standard naming practices.

## 🎉 Feature Updates 🎉
- Introducing the new model `stripe__invoice_details`.
- Updated the models `stripe__daily_overview` with additional daily and rolling metrics. 
- `subscription_item_id` has been added to the `stripe__invoice_line_items` model.
- Added the ability to union datasets across different schemas or databases. A new column populating each model called `source_relation` will specify the source of each record. 

For more information please refer to the [README](https://github.com/fivetran/dbt_stripe/blob/main/README.md) and [stripe.yml](https://github.com/fivetran/dbt_stripe/blob/main/models/stripe.yml)

# dbt_stripe v0.8.0

## 🚨 Breaking Changes 🚨:
[PR #48](https://github.com/fivetran/dbt_stripe/pull/48) includes the following breaking changes:
- Dispatch update for dbt-utils to dbt-core cross-db macros migration. Specifically `{{ dbt_utils.<macro> }}` have been updated to `{{ dbt.<macro> }}` for the below macros:
    - `any_value`
    - `bool_or`
    - `cast_bool_to_text`
    - `concat`
    - `date_trunc`
    - `dateadd`
    - `datediff`
    - `escape_single_quotes`
    - `except`
    - `hash`
    - `intersect`
    - `last_day`
    - `length`
    - `listagg`
    - `position`
    - `replace`
    - `right`
    - `safe_cast`
    - `split_part`
    - `string_literal`
    - `type_bigint`
    - `type_float`
    - `type_int`
    - `type_numeric`
    - `type_string`
    - `type_timestamp`
    - `array_append`
    - `array_concat`
    - `array_construct`
- For `current_timestamp` and `current_timestamp_in_utc` macros, the dispatch AND the macro names have been updated to the below, respectively:
    - `dbt.current_timestamp_backcompat`
    - `dbt.current_timestamp_in_utc_backcompat`
- Dependencies on `fivetran/fivetran_utils` have been upgraded, previously `[">=0.3.0", "<0.4.0"]` now `[">=0.4.0", "<0.5.0"]`.
- Updated README to include instructions on how to use metadata variable in cases of dictionary arguments. ([#51](https://github.com/fivetran/dbt_stripe/pull/51))
# dbt_stripe v0.7.4
## 🎉 Feature Updates
- Included the `subscription_item_id` field within the `stripe__invoice_line_items` model. ([#50](https://github.com/fivetran/dbt_stripe/pull/50))
- BuildKite testing has been added. ([#52](https://github.com/fivetran/dbt_stripe/pull/52))

## Contributors
- [LewisDavies](https://github.com/LewisDavies) ([#50](https://github.com/fivetran/dbt_stripe/pull/50))

# dbt_stripe v0.7.3
## 🎉 Feature Updates
- Included the `currency` field within the `stripe__invoice_line_items` model. ([#44](https://github.com/fivetran/dbt_stripe/pull/47))

## Contributors
- [ccbrandenburg](https://github.com/ccbrandenburg) ([#44](https://github.com/fivetran/dbt_stripe/pull/47))


# dbt_stripe v0.7.2

## 🎉 Feature Updates
- Databricks compatibility 🧱 ([#44](https://github.com/fivetran/dbt_stripe/pull/44))


# dbt_stripe v0.7.1
## Feature Updates 🎉
- README updates for easier package navigation and understanding. ([#41](https://github.com/fivetran/dbt_stripe/pull/41))
## Under the Hood
- Updating the package dependency to reference the proper [">=0.7.0", "<0.8.0"] version range of `dbt_stripe_source`. ([#41](https://github.com/fivetran/dbt_stripe/pull/41))


# dbt_stripe v0.7.0
## 🚨 Breaking Changes 🚨
- Stripe connectors set up after February 09, 2022 no longer sync the `subscription` table; however, a newer `subscription_history` table is synced. To account for this change a variable `stripe__subscription_history` has been added to the package project to allow for users to define if their source contains the `subscription_history` table. ([#37](https://github.com/fivetran/dbt_stripe_source/pull/37))
  - By default this variable is set to `false`. If you still have the `subscription` table, then there is no adjustment needed on your end. If you do have the `subscription_history` table then you will want to set the variable to `true`. 
  - Similarly, if you have both tables, then I highly encourage you start leveraging the `subscription_history` source table in your package.
  - This package now points to the latest `dbt_stripe_source` package version which accounts for the above update. ([#33](https://github.com/fivetran/dbt_stripe/pull/33) and [#34](https://github.com/fivetran/dbt_stripe/pull/34))

## 🐞 Bug Fixes 🐞
- [#35](https://github.com/fivetran/dbt_stripe/issues/35): Fix issue with timezone conversion in postgres by updating the `date_timezone` macro with postgres functionality. [@johnf](https://github.com/johnf)
- Added Postgres support for the Stripe package. 
- [See PR #37](https://github.com/fivetran/dbt_stripe/pull/37)

## Contributors
- [nachimehta](https://github.com/nachimehta) ([#37](https://github.com/fivetran/dbt_stripe_source/pull/37))

# dbt_stripe v0.6.1
## 🐞 Bug Fixes 🐞
- [#24](https://github.com/fivetran/dbt_stripe/issues/24): Updating docs to add `dbt_stripe` documentation in addition to `dbt_stripe_source` documentation.
- [#27](https://github.com/fivetran/dbt_stripe/issues/27): Updating `models/stripe__customer_overview.sql` to use `max` instead of `min` for calculating `most_recent_sale_date`. 
- [#28](https://github.com/fivetran/dbt_stripe/issues/28): Updating `models/stripe__customer_overview.sql` to include "No Associated Customer" records. 
  - This PR accounts for when a transaction may be tied to a customer_id that has not yet synced into the customers table due primarily due to a sync lapse between the tables; in which case, the customer_description field will be "No Associated Customer". 
  - Each "No Associated Customers" record will be an individual row, since we can not predictably do any group bys due to the `stripe__customer_metadata` variable variability in both datatype and number of metadata fields.

# dbt_stripe v0.6.0
🎉 dbt v1.0.0 Compatibility 🎉
## 🚨 Breaking Changes 🚨
- Adjusts the `require-dbt-version` to now be within the range [">=1.0.0", "<2.0.0"]. Additionally, the package has been updated for dbt v1.0.0 compatibility. If you are using a dbt version <1.0.0, you will need to upgrade in order to leverage the latest version of the package.
  - For help upgrading your package, I recommend reviewing this GitHub repo's Release Notes on what changes have been implemented since your last upgrade.
  - For help upgrading your dbt project to dbt v1.0.0, I recommend reviewing dbt-labs [upgrading to 1.0.0 docs](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-1-0-0) for more details on what changes must be made.
- Upgrades the package dependency to refer to the latest `dbt_stripe_source`. Additionally, the latest `dbt_stripe_source` package has a dependency on the latest `dbt_fivetran_utils`. Further, the latest `dbt_fivetran_utils` package also has a dependency on `dbt_utils` [">=0.8.0", "<0.9.0"].
  - Please note, if you are installing a version of `dbt_utils` in your `packages.yml` that is not in the range above then you will encounter a package dependency error.

# dbt_stripe v0.5.1

## Features
- Add functionality to include customer metadata in `stripe__customer_overview`. ([#21](https://github.com/fivetran/dbt_stripe/pull/21)) The customer metadata is passed in from the `stg_stripe__customer` model in the Stripe source package.
    - For more information refer to the [Stripe source package CHANGELOG](https://github.com/fivetran/dbt_stripe_source/blob/main/CHANGELOG.md)

# dbt_stripe v0.1.0 -> v0.5.0
- Refer to the relevant release notes on the Github repository for specific details for the previous releases. Thank you!
