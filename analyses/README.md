# Stripe Analyses
> Note: The compiled SQL within the analyses folder references the [stripe__subscription_item_mrr_report](https://github.com/fivetran/dbt_stripe/blob/master/models/stripe_financial_reports/stripe__subscription_item_mrr_report.sql) model. You must execute `dbt run` before compiling the analysis SQL.


## Analysis SQL
| **SQL**                | **Description**                                                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| [stripe__arr_snapshot_analysis](https://github.com/fivetran/dbt_stripe/blob/master/analyses/stripe__arr_snapshot_analysis.sql) | This analysis generates a high-level ARR snapshot report for your business that you can use for revenue forecasting. The analysis provides year-end ARR metrics by aggregating MRR data from the last month of each calendar year and multiplying by 12. The SQL references the `stripe__subscription_item_mrr_report` model and aggregates metrics by currency. Subscriptions must be enabled for this report to compile correctly. |
| [stripe__customer_mrr_analysis](https://github.com/fivetran/dbt_stripe/blob/master/analyses/stripe__customer_mrr_analysis.sql) | This analysis generates an MRR report at the customer level that you can use for retention reporting and cohort analysis. The analysis aggregates monthly recurring revenue by customer and month, providing insights into customer-level revenue trends over time. The SQL references the `stripe__subscription_item_mrr_report` model. You can also generate this report at the overall business level by removing the customer_id field from the aggregation. |

## SQL Compile Instructions
You can leverage the above SQL using the [analysis functionality of dbt](https://docs.getdbt.com/docs/building-a-dbt-project/analyses/). To compile the SQL, perform the following steps:
- Execute `dbt run` to create the package models.
- Execute `dbt compile` to generate the target-specific SQL.
- Navigate to your project's `/target/compiled/stripe/analyses` directory.
- Copy the desired analysis code (`stripe__arr_snapshot_analysis` or `stripe__customer_mrr_analysis`) and run it in your data warehouse.
- Confirm the revenue metrics match your expected subscription and billing patterns.
- Analyze the ARR snapshots and customer-level MRR trends to identify growth opportunities, retention patterns, and revenue forecasting insights.

## Contributions
Don't see a compiled SQL statement you'd like to include? Notice any bugs when compiling and running the analysis SQL? If so, we highly encourage and welcome contributions to this package! If interested, the best first step is [opening a feature request](https://github.com/fivetran/dbt_stripe/issues/new?template=feature-request.yml).