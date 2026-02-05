# dbt_stripe v1.5.0

## Schema Change
**1 total change • 1 possible breaking change**
| **Data Model** | **Change type** | **Old** | **New** | **Notes** |
| -------------- | --------------- | ------------ | ------------ | --------- |
| All models | Single-connection `source_relation` value | Empty string (`''`) | `<stripe_database>.<stripe_schema>` |  |

## Feature Update
- Introduces support for the newer, more flexible unioning framework. Previously, to run the package on multiple Stripe sources at once, you could only use the `union_schemas` variable OR `union_databases` (mutually exclusive). While these setups are still supported for backwards compatibility, we recommend using `stripe_sources` instead, which can be configured as such:

```yml
# dbt_project.yml

vars:
  stripe:
    stripe_sources:
      - database: connection_1_destination_name # Required
        schema: connection_1_schema_name # Required
        name: connection_1_source_name # Required only if following this step: https://github.com/fivetran/dbt_stripe/blob/main/README.md#recommended-incorporate-unioned-sources-into-dag

      - database: connection_2_destination_name
        schema: connection_2_schema_name
        name: connection_2_source_name
```
- See the [README](https://github.com/fivetran/dbt_stripe/blob/main/README.md#option-b-union-multiple-connections) for more details.
- Updates end models (`stripe__balance_transactions`, `stripe__customer_overview`, `stripe__invoice_details`, `stripe__invoice_line_item_details`, `stripe__subscription_details`) to dynamically include metadata fields from staging models when metadata variables are configured. 
  - Adds select_metadata_columns macro to handle both dictionary and alias variable metadata inputs.
  - The expectation is that customers will only ever input single level key value pairs into the variables.
  - Currently, metadata fields from `stge_stripe__customer`, `stg_stripe__charge`, `stg_stripe__invoice`, and `stge_stripe__subscription` are supported. We are open to supporting others, but require feedback. Please open a [support ticket](https://support.fivetran.com/hc/en-us) to request metadata fields from additional staging models.

## Under the Hood
- Updates all tmp staging models to conditionally use either the new `stripe_union_connections` macro (when `stripe_sources` is configured) or the legacy `fivetran_utils.union_data` macro (for backward compatibility).
- Updates all staging models to use the new `stripe.apply_source_relation()` macro instead of `fivetran_utils.source_relation()`.
- Adds `metadata` column to `get_coupon_columns()` macro and `coupon_data.csv` seed file.
- Adds table variables for `stripe__using_transfers` and `stripe__using_payouts` to quickstart.yml.
- Updates integration test seed data for customer and invoice tables.

# dbt_stripe v1.4.0
[PR #138](https://github.com/fivetran/dbt_stripe/pull/138) includes the following updates:

## Schema/Data Change
**3 total change • 0 possible breaking changes**

| Data Model(s) | Change type | Old | New | Notes |
| ---------- | ----------- | -------- | -------- | ----- |
| [`stripe__subscription_item_mrr_report`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__subscription_item_mrr_report) | New End Model | | | Each record represents a subscription item for a given month with MRR metrics for both contract and billed/net mrr, movement classification, and monthly discounts applied. Tracks MRR changes over time, classifying each month as new, expansion, contraction, churned, reactivation, or unchanged. If you notice any discrepencies in MRR calculations with this new model, please open up a [support ticket](https://support.fivetran.com/hc/en-us). |
| [`stg_stripe__coupon`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stg_stripe__coupon) | New Staging Model | | | Staging model for Stripe coupon data. |
| [`stg_stripe__coupon_tmp`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stg_stripe__coupon_tmp) | New Temp Model | | | |
| [`stg_stripe__price_plan`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stg_stripe__price_plan) | Datatype casts| | `recurring_interval` field as `string`<br>`recurring_interval_count` field as `integer`<br>`price_plan_id` field as `string` | Avoids datatype errors. |
| [`stg_stripe__subscription_item`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stg_stripe__subscription_item) | Datatype casts | |  `plan_id` field as `string` | Avoids datatype errors. |


## Feature Update
- Adds new analyses folder with advanced revenue reporting:
  - `stripe__arr_snapshot_analysis`: Generates a high-level ARR snapshot report for the entire business for revenue forecasting.
  - `stripe__customer_mrr_analysis`: Generates an MRR report at the customer level for retention reporting and cohort analysis.
   - These analysis files reference the `stripe__subscription_item_mrr_report` model and can be compiled using `dbt compile` and executed directly in your data warehouse.

## Documentation
- Adds comprehensive column documentation for `stripe__subscription_item_mrr_report` in `stripe.yml`.
- Adds README in the analysis folder with instructions on how to compile and use the analysis SQL.

## Under the Hood
- Adds consistency test for `stripe__subscription_item_mrr_report` model.
- Updates `integration_tests/seeds/price_data.csv` with additional test data.
- Adds `stripe__subscription_item_mrr_report` model to quickstart.yml public models list.

# dbt_stripe v1.3.0-a4
[PR #138](https://github.com/fivetran/dbt_stripe/pull/138) includes the following update:

## Under the Hood
- Removes dependency on `int_stripe__date_spine` from `stripe__subscription_item_mrr_report` so users do not need to have the account table enabled to use the MRR report.
- Explicitly casts `recurring_interval` field as string to avoid datatype errors.

# dbt_stripe v1.3.0-a3
[PR #138](https://github.com/fivetran/dbt_stripe/pull/138) includes the following update:

## Under the Hood
- Adds docs with the updated manifest to ensure deployment of our Quickstart models.

# dbt_stripe v1.3.0-a2
[PR #138](https://github.com/fivetran/dbt_stripe/pull/138) includes the following updates:


## Under the Hood
- Adds `stripe__subscription_item_mrr_report` model to quickstart.yml public models list.

# dbt_stripe v1.3.0-a1
[PR #138](https://github.com/fivetran/dbt_stripe/pull/138) includes the following updates:

## Schema/Data Change
**1 total change • 0 possible breaking changes**

| Data Model(s) | Change type | Old | New | Notes |
| ---------- | ----------- | -------- | -------- | ----- |
| [`stripe__subscription_item_mrr_report`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__subscription_item_mrr_report) | New End Model | | | Each record represents a subscription item for a given month with MRR metrics and movement classification. Tracks MRR changes over time, classifying each month as new, expansion, contraction, churned, reactivation, or unchanged. |

## Feature Update
- Adds new analyses folder with compiled SQL for advanced revenue reporting:
 - `stripe__arr_snapshot_analysis`: Generates a high-level ARR snapshot report for the entire business for revenue forecasting.
 - `stripe__customer_mrr_analysis`: Generates an MRR report at the customer level for retention reporting and cohort analysis.
 - These analysis files reference the `stripe__subscription_item_mrr_report` model and can be compiled using `dbt compile` and executed directly in your data warehouse.

## Bug Fix
- Fixes a circular reference in `stg_stripe__price_plan` where the model incorrectly references itself instead of `stg_stripe__price_plan_tmp`, causing compilation errors.

## Documentation
- Adds comprehensive column documentation for `stripe__subscription_item_mrr_report` in `stripe.yml`.
- Adds README in the analysis folder with instructions on how to compile and use the analysis SQL.

## Under the Hood
- Adds consistency test for `stripe__subscription_item_mrr_report` model.
- Updates `integration_tests/seeds/price_data.csv` with additional test data.

# dbt_stripe v1.3.0

[PR #139](https://github.com/fivetran/dbt_stripe/pull/139) includes the following updates:

## Documentation
- Updates README with standardized Fivetran formatting.

## Under the Hood
- In the `quickstart.yml` file:
  - Adds `table_variables` for relevant sources to prevent missing sources from blocking downstream Quickstart models.
  - Adds `supported_vars` for Quickstart UI customization.

# dbt_stripe v1.2.0

[PR #137](https://github.com/fivetran/dbt_stripe/pull/137) includes the following updates:

## Features
  - Increases the required dbt version upper limit to v3.0.0

# dbt_stripe v1.1.0
[PR #125](https://github.com/fivetran/dbt_stripe/pull/125) includes the following updates:

## Schema/Data Changes
