# dbt_stripe v0.7.0
## 🚨 Breaking Changes 🚨
- Bug fix within the `dbt_stripe_source` package where the `subscription` source table didn't match the most recent [Stripe ERD](https://docs.google.com/presentation/d/1zyxgbaOjgBt3NsY0OfsiGsWDIefcBc-R1lHWlMltCYU/edit#slide=id.gd0264d4694_14_1). The table and relevant tests/project information have now been updated to reference the new `subscription_history` source table. Before upgrading, please ensure your Stripe connector includes the `subscription_history` table. ([#37](https://github.com/fivetran/dbt_stripe_source/pull/37))
  - This package now points to the latest `dbt_stripe_source` package version which accounts for the above bug. ([#33](https://github.com/fivetran/dbt_stripe/pull/33) and [#34](https://github.com/fivetran/dbt_stripe/pull/34))
## Features
- Includes a new variable `stripe__keep_subscription_history` which allows users to enable or disable the historical records within the `subscription` models. By default this variable is set to `false` and will only include active records within your downstream subscription models. ([#38](https://github.com/fivetran/dbt_stripe_source/pull/38))
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
