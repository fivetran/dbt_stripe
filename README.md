# Stripe dbt Package ([Docs](https://fivetran.github.io/dbt_stripe/))

<p align="left">
    <a alt="License"
        href="https://github.com/fivetran/dbt_stripe/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_Core™_version->=1.3.0,_<3.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
    <a alt="Fivetran Quickstart Compatible"
        href="https://fivetran.com/docs/transformations/dbt/quickstart">
        <img src="https://img.shields.io/badge/Fivetran_Quickstart_Compatible%3F-yes-green.svg" /></a>
</p>

## What does this dbt package do?
- Produces modeled tables that leverage Stripe data from [Fivetran's connector](https://fivetran.com/docs/applications/stripe) in the format described by [this ERD](https://fivetran.com/docs/applications/stripe#schemainformation).
- Enables you to better understand your Stripe transactions. The package achieves this by performing the following:
    - Enhance the balance transaction entries with useful fields from related tables.
    - Generate metrics tables that allow you to better understand your account activity over time or at a customer level. These time-based metrics are available on a daily, weekly, monthly, and quarterly level.
- Generates a comprehensive data dictionary of your source and modeled Stripe data through the [dbt docs site](https://fivetran.github.io/dbt_stripe/).

<!--section="stripe_transformation_model"-->
The following table provides a detailed list of all tables materialized within this package by default.
> TIP: See more details about these tables in the package's [dbt docs site](https://fivetran.github.io/dbt_stripe/#!/overview?g_v=1).

| **Table** | **Details** |
|-----------|-------------|
| [`stripe__balance_transactions`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__balance_transactions) | Represents each change to your Stripe balance with transaction context.<br><br>**Example Analytics Questions:**<br>• What types of transactions are most impacting my Stripe balance?<br>• How much did fees, refunds, or disputes reduce net revenue this quarter? |
| [`stripe__invoice_details`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__invoice_details) | Contains invoice records with associated charge, customer, and subscription data.<br><br>**Example Analytics Questions:**<br>• What is the average invoice value by customer segment?<br>• Which customers have the highest outstanding invoices? |
| [`stripe__invoice_line_item_details`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__invoice_line_item_details) | Includes line items with charge, customer, subscription, and pricing details.<br><br>**Example Analytics Questions:**<br>• Which products or services contribute most to total invoiced revenue?<br>• Are there any products consistently discounted or refunded? |
| [`stripe__daily_overview`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__daily_overview) | Summarizes daily and rolling Stripe transaction totals by type.<br><br>**Example Analytics Questions:**<br>• What is the trend in daily net payments and refunds?<br>• What is the MRR trend over the last 6 months? |
| [`stripe__subscription_details`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__subscription_details) | Contains subscription records with customer and payment metrics.<br><br>**Example Analytics Questions:**<br>• How many active subscriptions are there by plan or product?<br>• What is the average customer subscription length before cancellation? |
| [`stripe__subscription_item_mrr_report`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__subscription_item_mrr_report) | Tracks monthly recurring revenue (MRR) at the subscription item level with movement classification.<br><br>**Example Analytics Questions:**<br>• What is the total MRR and how is it trending month over month?<br>• What portion of MRR is from expansion vs new customers vs churn? |
| [`stripe__customer_overview`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__customer_overview) | Shows customer-level metrics with transaction details and associations.<br><br>**Example Analytics Questions:**<br>• Who are the top 10 customers by total lifetime value?<br>• How many customers made a payment in the last 90 days? |
| [`stripe__activity_itemized_2`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__activity_itemized_2) | Lists balance transactions with invoice, fee, refund, and customer data.<br><br>**Example Analytics Questions:**<br>• What are the exact transaction-level fees for each invoice or customer?<br>• How much are we paying in interchange and platform fees per transaction? |
| [`stripe__balance_change_from_activity_itemized_3`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__balance_change_from_activity_itemized_3) | Reconciles Stripe balance changes like a detailed bank statement.<br><br>**Example Analytics Questions:**<br>• What was the source of each Stripe balance change over the last month?<br>• How accurate is my accounting ledger compared to Stripe's balance records? |
| [`stripe__ending_balance_reconciliation_itemized_4`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__ending_balance_reconciliation_itemized_4) | Matches bank payouts with unsettled Stripe transactions.<br><br>**Example Analytics Questions:**<br>• Which transactions remain unsettled as of the last payout?<br>• Do all automatic payouts reconcile fully with balance changes? |
| [`stripe__payout_itemized_3`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__payout_itemized_3) | Details expected and actual payout amounts and statuses.<br><br>**Example Analytics Questions:**<br>• When should I expect my next payout, and for how much?<br>• Are there any delayed or failed payouts that need follow-up? |
| [`stripe__line_item_enhanced`](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__line_item_enhanced) | Provides unified reporting across billing platforms on product, customer, and revenue metrics. See the [Fivetran Billing Model Streamlit App](https://fivetran-billing-model.streamlit.app/) for more details.<br><br>**Example Analytics Questions:**<br>• What are the top revenue-generating products or SKUs?<br>• What is the average revenue per user (ARPU) by subscription plan? |


### Example Visualizations
Curious what these tables can do? Check out example visualizations from the [stripe__line_item_enhanced](https://fivetran.github.io/dbt_stripe/#!/model/model.stripe.stripe__line_item_enhanced) table in the [Fivetran Billing Model Streamlit App](https://fivetran-billing-model.streamlit.app/), and see how you can use these tables in your own reporting. Below is a screenshot of an example report—explore the app for more.

<p align="center">
<a href="https://fivetran-billing-model.streamlit.app/">
    <img src="https://raw.githubusercontent.com/fivetran/dbt_stripe/main/images/streamlit_example.png" alt="Streamlit Billing Model App" width="75%">
</a>
</p>

### Materialized Models
Each Quickstart transformation job run materializes 58 models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.
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
    version: "1.3.0-a3"
```
> All required sources and staging models are now bundled into this transformation package. Do not include `fivetran/stripe_source` in your `packages.yml` since this package has been deprecated.

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
    stripe__using_subscriptions:   False  #Disable if you are not using the subscription, and plan/price tables.
    stripe__using_credit_notes:    True   #Enable if you are using the credit note tables.
```
### (Optional) Step 5: Additional configurations
<details open><summary>Expand to view configurations</summary>

#### Enabling Standardized Billing Model
This package contains the `stripe__line_item_enhanced` model which constructs a comprehensive, denormalized analytical table that enables reporting on key revenue, subscription, customer, and product metrics from your billing platform. It’s designed to align with the schema of the `*__line_item_enhanced` model found in Recurly, Recharge, Stripe, Shopify, and Zuora, offering standardized reporting across various billing platforms. To see the kinds of insights this model can generate, explore example visualizations in the [Fivetran Billing Model Streamlit App](https://fivetran-billing-model.streamlit.app/). This model is enabled by default. To disable it, set the `stripe__standardized_billing_model_enabled` variable to `false` in your `dbt_project.yml`:

```yml
vars:
  stripe__standardized_billing_model_enabled: false # true by default.
```

#### Unioning Multiple Stripe Connections
If you have multiple Stripe connections you would like to use this package on simultaneously, we have added the ability to do so. Data from disparate connections will be unioned together and be passed downstream to the end models. The `source_relation` column will specify where each record comes from. To use this functionality, you will need to either set the `stripe_union_schemas` or `stripe_union_databases` variables.

```yml
# dbt_project.yml

...
config-version: 2

vars:
    stripe_union_schemas: ['stripe_us','stripe_mx'] # use this if the data is in different schemas/datasets of the same database/project
    stripe_union_databases: ['stripe_db_1','stripe_db_2'] # use this if the data is in different databases/projects but uses the same schema name
```

If you are using `stripe_union_schemas` and would like to:
- Run freshness tests on multiple Stripe sources
- Synchronize model runs with your Stripe connections in Fivetran through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt#transformationsfordbtcore) (this is also achievable through Fivetran [Quickstart](https://fivetran.com/docs/transformations/quickstart), which would create separate sets of models for each Stripe source rather than one set of unioned models)
- Incorporate all Stripe source tables into your project's DAG

Please follow the below steps:
1. Set the `stripe_schema` variable to _one_ of the schemas you have provided to `stripe_union_schemas`.
2. For the rest of the schemas that you have provided to `stripe_union_schemas`, you will need to create a [source](https://docs.getdbt.com/docs/build/sources) for them in a `.yml` file in your project. This will involve copying and pasting all of the table definitions from the package's native [Stripe source](https://github.com/fivetran/dbt_stripe/blob/main/models/staging/src_stripe.yml#L15).

<details><summary>Expand for source definition template</summary>
<br>

```yml
sources:
  - name: <name> # Should match the name of the schema
    database: <database_name> # You can input the database directly or use {{ var('stripe_database') }}
    schema: <schema_name> 

    loader: fivetran

    config:
      loaded_at_field: _fivetran_synced
      freshness: # This is what the package uses, but adjust to your liking
        warn_after: { count: 72, period: hour }
        error_after: { count: 168, period: hour }

    tables: &stripe-tables # You can use yaml anchors to only write out definitions once (in the next source use *stripe-tables ) - see https://support.atlassian.com/bitbucket-cloud/docs/yaml-anchors/ for details
      - name: balance_transaction
        identifier: "{{ var('stripe_balance_transaction_identifier', 'balance_transaction')}}"
        description: Balance transactions represent funds moving through your Stripe account. They're created for every type of transaction that comes into or flows out of your Stripe account balance.
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: amount
            description: Gross amount of the transaction, in cents.
          - name: available_on
            description: The date the transaction’s net funds will become available in the Stripe balance.
          - name: connected_account_id
            description: The ID of the account connected to the transaction.
          - name: created
            description: '{{ doc("created") }}'
          - name: currency
            description: Three-letter ISO currency code, in lowercase.
          - name: description
            description: An arbitrary string attached to the object. Often useful for displaying to users.
          - name: exchange_rate
            description: The exchange rate used, if applicable, for this transaction. Specifically, if money was converted from currency A to currency B, then the amount in currency A, times exchange_rate, would be the amount in currency B.
          - name: fee
            description: fees (in cents) paid for this transaction.
          - name: net
            description: Net amount of the transaction, in cents.
          - name: reporting_category
            description: Improves on the type field by providing a more-useful grouping for most finance and reporting purposes.
          - name: source
            description: The Stripe object to which this transaction is related.
          - name: status
            description: If the transaction’s net funds are available in the Stripe balance yet. Either 'available' or 'pending'.
          - name: type
            description: The type of transaction.  Possible values are adjustment, advance, advance_funding, application_fee, application_fee_refund, charge, connect_collection_transfer, issuing_authorization_hold, issuing_authorization_release, issuing_dispute, issuing_transaction, payment, payment_failure_refund, payment_refund, payout, payout_cancel, payout_failure, refund, refund_failure, reserve_transaction, reserved_funds, stripe_fee, stripe_fx_fee, tax_fee, topup, topup_reversal, transfer, transfer_cancel, transfer_failure, or transfer_refund.

      - name: card
        identifier: "{{ var('stripe_card_identifier', 'card')}}"
        description: Details of a credit card that has been saved to the system.
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: account_id
            description: ID of account associated with this card.
          - name: address_city
            description: City, district, suburb, town, or village.
          - name: address_country
            description: Two-letter country code (ISO 3166-1 alpha-2).
          - name: address_line_1
            description: Address line 1 (e.g., street, PO Box, or company name).
          - name: address_line_2
            description: Address line 2 (e.g., apartment, suite, unit, or building).
          - name: address_state
            description: State/County/Province/Region.
          - name: address_zip
            description: ZIP or postal code.
          - name: brand
            description: Card brand. Can be American Express, Diners Club, Discover, JCB, MasterCard, UnionPay, Visa, or Unknown.
          - name: country
            description: Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you’ve collected.
          - name: created
            description: '{{ doc("created") }}'
          - name: customer_id
            description: The customer that this card belongs to.  NULL if belongs to an account or recipient.
          - name: name
            description: Cardholder name
          - name: recipient
            description: The recipient that this card belongs to. NULL if the card belongs to a customer or account instead.
          - name: funding
            description: Card funding type. Can be credit, debit, prepaid, or unknown.
          - name: wallet_type
            description: The type of the card wallet, one of amex_express_checkout, apple_pay, google_pay, masterpass, samsung_pay, or visa_checkout. An additional hash is included on the Wallet subhash with a name matching this value. It contains additional information specific to the card wallet type.
          - name: three_d_secure_authentication_flow
            description: For authenticated transactions, how the customer was authenticated by the issuing bank.
          - name: three_d_secure_result
            description: Indicates the outcome of 3D Secure authentication.
          - name: three_d_secure_result_reason
            description: Additional information about why 3D Secure succeeded or failed based on the result.
          - name: three_d_secure_version
            description: The version of 3D Secure that was used.

      - name: charge
        identifier: "{{ var('stripe_charge_identifier', 'charge')}}"
        description: To charge a credit or a debit card, you create a Charge object. You can retrieve and refund individual charges as well as list all charges. Charges are identified by a unique, random ID.
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: amount
            description: Amount intended to be collected by this payment. A positive integer representing how much to charge in the smallest currency unit (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency)
          - name: amount_refunded
            description: The amount of the charge, if any, that has been refunded.
          - name: application_fee_amount
            description: The amount of the application fee (if any) for the charge.
          - name: balance_transaction_id
            description: ID of the balance transaction that describes the impact of this charge on your account balance (not including refunds or disputes).
          - name: captured
            description: If the charge was created without capturing, this Boolean represents whether it is still uncaptured or has since been captured.
          - name: card_id
            description: ID of the card that was charged.
          - name: created
            description: '{{ doc("created") }}'
          - name: connected_account_id
            description: ID of account connected for this charge.
          - name: customer_id
            description: ID of the customer this charge is for if one exists.
          - name: description
            description: An arbitrary string attached to the object. Often useful for displaying to users.
          - name: failure_code
            description: Error code explaining reason for charge failure if available.
          - name: failure_message
            description: Message to user further explaining reason for charge failure if available.
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: paid
            description: true if the charge succeeded, or was successfully authorized for later capture.
          - name: payment_intent_id
            description: ID of the PaymentIntent associated with this charge, if one exists.
          - name: receipt_email
            description: This is the email address that the receipt for this charge was sent to.
          - name: receipt_number
            description: This is the transaction number that appears on email receipts sent for this charge.
          - name: refunded
            description: Whether the charge has been fully refunded. If the charge is only partially refunded, this attribute will still be false.
          - name: status
            description: The status of the payment is either succeeded, pending, or failed.
          - name: shipping_address_city
            description: City, district, suburb, town, or village.
          - name: shipping_address_country
            description: Two-letter country code (ISO 3166-1 alpha-2).
          - name: shipping_address_line_1
            description: Address line 1 (e.g., street, PO Box, or company name).
          - name: shipping_address_line_2
            description: Address line 2 (e.g., apartment, suite, unit, or building).
          - name: shipping_address_postal_code
            description: ZIP or postal code.
          - name: shipping_address_state
            description: State, county, province, or region.
          - name: shipping_carrier
            description: The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
          - name: shipping_name
            description: Recipient name.
          - name: shipping_phone
            description: Recipient phone (including extension).
          - name: shipping_tracking_number
            description: The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
          - name: source_id
            description: ID of the source associated. Source objects allow you to accept a variety of payment methods. They represent a customer's payment instrument, and can be used with the Stripe API just like a Card object, once chargeable, they can be charged, or can be attached to customers.
          - name: source_transfer
            description: The transfer ID which created this charge. Only present if the charge came from another Stripe account.
          - name: statement_descriptor
            description: Extra information about a source. This will appear on your customer’s statement every time you charge the source.
          - name: invoice_id
            description: The id of the invoice associated with this charge.
          - name: currency
            description: The currency of the charge.
          - name: created
            description: '{{ doc("created") }}'
          - name: livemode
            description: Indicates if this is a test charge.
          - name: payment_method_id
            description: Unique identifier for the payment method object used in this charge.
          - name: calculated_statement_descriptor
            description: The full statement descriptor that is passed to card networks, and that is displayed on your customers’ credit card and bank statements. Allows you to see what the statement descriptor looks like after the static and dynamic portions are combined.
          - name: billing_detail_address_city
            description: City, district, suburb, town, or village.
          - name: billing_detail_address_country
            description: Two-letter country code (ISO 3166-1 alpha-2).
          - name: billing_detail_address_line1
            description: Address line 1 (e.g., street, PO Box, or company name).
          - name: billing_detail_address_line2
            description: Address line 2 (e.g., apartment, suite, unit, or building).
          - name: billing_detail_address_postal_code
            description: ZIP or postal code.
          - name: billing_detail_address_state
            description: State, county, province, or region.
          - name: billing_detail_email
            description: Email address.
          - name: billing_detail_name
            description: Full name.
          - name: billing_detail_phone
            description: Billing phone number (including extension).

      - name: customer
        identifier: "{{ var('stripe_customer_identifier', 'customer')}}"
        description: Customer objects allow you to perform recurring charges, and to track multiple charges, that are associated with the same customer.
        config:
          freshness: null

        columns:
          - name: id
            description: Unique identifier for the object.
          - name: account_balance
            description: Current balance, if any, being stored on the customer. If negative, the customer has credit to apply to their next invoice. If positive, the customer has an amount owed that will be added to their next invoice.
          - name: address_city
            description: '{{ doc("city") }}'
          - name: address_country
            description: '{{ doc("country") }}'
          - name: address_line_1
            description: '{{ doc("line_1") }}'
          - name: address_line_2
            description: '{{ doc("line_2") }}'
          - name: address_postal_code
            description: '{{ doc("postal_code") }}'
          - name: address_state
            description: '{{ doc("state") }}'
          - name: balance
            description: Current balance, if any, being stored on the customer. If negative, the customer has credit to apply to their next invoice. If positive, the customer has an amount owed that will be added to their next invoice. The balance does not refer to any unpaid invoices; it solely takes into account amounts that have yet to be successfully applied to any invoice. This balance is only taken into account as invoices are finalized.
          - name: bank_account_id
            description: ID of the bank account associated with this customer.
          - name: created
            description: '{{ doc("created") }}'
          - name: currency
            description: Three-letter ISO code for the currency the customer can be charged in for recurring billing purposes.
          - name: default_card_id
            description: ID for the default card used by the customer.
          - name: delinquent
            description: When the customer’s latest invoice is billed by charging automatically, delinquent is true if the invoice’s latest charge is failed. When the customer’s latest invoice is billed by sending an invoice, delinquent is true if the invoice is not paid by its due date.
          - name: description
            description: An arbitrary string attached to the object. Often useful for displaying to users.
          - name: email
            description: The customer’s email address.
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: name
            description: Customer name.
          - name: phone
            description: Customer's phone number.
          - name: shipping_address_city
            description: Attribute of the customer's shipping address.
          - name: shipping_address_country
            description: Attribute of the customer's shipping address.
          - name: shipping_address_line_1
            description: Attribute of the customer's shipping address.
          - name: shipping_address_line_2
            description: Attribute of the customer's shipping address.
          - name: shipping_address_postal_code
            description: Attribute of the customer's shipping address.
          - name: shipping_address_state
            description: Attribute of the customer's shipping address.
          - name: shipping_name
            description: Attribute of the customer's shipping address.
          - name: shipping_phone
            description: Attribute of the customer's shipping address.
          - name: livemode
            description: Indicates if this is a test customer.
          - name: is_deleted
            description: Boolean reflecting whether the customer has been deleted in Stripe.

      - name: dispute
        identifier: "{{ var('stripe_dispute_identifier', 'dispute')}}"
        description: The details of a dispute related to a charge. A dispute occurs when a customer questions your charge with their card issuer. When this happens, you're given the opportunity to respond to the dispute with evidence that shows that the charge is legitimate.
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: amount
            description: Disputed amount. Usually the amount of the charge, but can differ (usually because of currency fluctuation or because only part of the order is disputed).
          - name: balance_transaction
            description: List of zero, one, or two balance transactions that show funds withdrawn and reinstated to your Stripe account as a result of this dispute.
          - name: charge_id
            description: ID of the charge that was disputed.
          - name: connected_account_id
            description: Account id associated with this dispute.
          - name: created
            description: Time at which the object was created. Measured in seconds since the Unix epoch.
          - name: currency
            description: Three-letter ISO currency code, in lowercase. Must be a supported currency.
          - name: evidence_access_activity_log
            description: Any server or activity logs showing proof that the customer accessed or downloaded the purchased digital product. This information should include IP addresses, corresponding timestamps, and any detailed recorded activity. Has a maximum character count of 20,000.
          - name: evidence_billing_address
            description: The billing address provided by the customer.
          - name: evidence_cancellation_policy
            description: (ID of a file upload) Your subscription cancellation policy, as shown to the customer.
          - name: evidence_cancellation_policy_disclosure
            description: An explanation of how and when the customer was shown your refund policy prior to purchase. Has a maximum character count of 20,000.
          - name: evidence_cancellation_rebuttal
            description: A justification for why the customer’s subscription was not canceled. Has a maximum character count of 20,000.
          - name: evidence_customer_communication
            description: (ID of a file upload) Any communication with the customer that you feel is relevant to your case. Examples include emails proving that the customer received the product or service, or demonstrating their use of or satisfaction with the product or service.
          - name: evidence_customer_email_address
            description: The email address of the customer.
          - name: evidence_customer_name
            description: The name of the customer.
          - name: evidence_customer_purchase_ip
            description: The IP address that the customer used when making the purchase.
          - name: evidence_customer_signature
            description: (ID of a file upload) A relevant document or contract showing the customer’s signature.
          - name: evidence_details_due_by
            description: Date by which evidence must be submitted in order to successfully challenge dispute. Will be 0 if the customer’s bank or credit card company doesn’t allow a response for this particular dispute.
          - name: evidence_details_has_evidence
            description: Whether evidence has been staged for this dispute.
          - name: evidence_details_past_due
            description: Whether the last evidence submission was submitted past the due date. Defaults to false if no evidence submissions have occurred. If true, then delivery of the latest evidence is not guaranteed.
          - name: evidence_details_submission_count
            description: The number of times evidence has been submitted. Typically, you may only submit evidence once.
          - name: evidence_duplicate_charge_documentation
            description: (ID of a file upload) Documentation for the prior charge that can uniquely identify the charge, such as a receipt, shipping label, work order, etc. This document should be paired with a similar document from the disputed payment that proves the two payments are separate.
          - name: evidence_duplicate_charge_explanation
            description: An explanation of the difference between the disputed charge versus the prior charge that appears to be a duplicate. Has a maximum character count of 20,000.
          - name: evidence_duplicate_charge_id
            description: The Stripe ID for the prior charge which appears to be a duplicate of the disputed charge.
          - name: evidence_product_description
            description: A description of the product or service that was sold. Has a maximum character count of 20,000.
          - name: evidence_receipt
            description: (ID of a file upload) Any receipt or message sent to the customer notifying them of the charge.
          - name: evidence_refund_policy
            description: (ID of a file upload) Your refund policy, as shown to the customer.
          - name: evidence_refund_policy_disclosure
            description: Documentation demonstrating that the customer was shown your refund policy prior to purchase. Has a maximum character count of 20,000.
          - name: evidence_refund_refusal_explanation
            description: A justification for why the customer is not entitled to a refund. Has a maximum character count of 20,000.
          - name: evidence_service_date
            description: The date on which the customer received or began receiving the purchased service, in a clear human-readable format.
          - name: evidence_service_documentation
            description: (ID of a file upload) Documentation showing proof that a service was provided to the customer. This could include a copy of a signed contract, work order, or other form of written agreement.
          - name: evidence_shipping_address
            description: The address to which a physical product was shipped. You should try to include as complete address information as possible.
          - name: evidence_shipping_carrier
            description: The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc. If multiple carriers were used for this purchase, please separate them with commas.
          - name: evidence_shipping_date
            description: The date on which a physical product began its route to the shipping address, in a clear human-readable format.
          - name: evidence_shipping_documentation
            description: (ID of a file upload) Documentation showing proof that a product was shipped to the customer at the same address the customer provided to you. This could include a copy of the shipment receipt, shipping label, etc. It should show the customer’s full shipping address, if possible.
          - name: evidence_shipping_tracking_number
            description: The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
          - name: evidence_uncategorized_file
            description: (ID of a file upload) Any additional evidence or statements.
          - name: evidence_uncategorized_text
            description: Any additional evidence or statements. Has a maximum character count of 20,000.
          - name: is_charge_refundable
            description: Boolean ff true, it is still possible to refund the disputed payment. Once the payment has been fully refunded, no further funds will be withdrawn from your Stripe account as a result of this dispute.
          - name: livemode
            description: Indicates if this is a test dispute.
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: reason
            description: Reason given by cardholder for dispute. Possible values are bank_cannot_process, check_returned, credit_not_processed, customer_initiated, debit_not_authorized, duplicate, fraudulent, general, incorrect_account_details, insufficient_funds, product_not_received, product_unacceptable, subscription_canceled, or unrecognized.
          - name: status
            description: Current status of dispute. Possible values are warning_needs_response, warning_under_review, warning_closed, needs_response, under_review, won, or lost.

      - name: fee
        identifier: "{{ var('stripe_fee_identifier', 'fee')}}"
        description: The details of a fee associated with a balance_transaction
        columns:
          - name: balance_transaction_id
            description: ID of the balance transaction entry the fee applies to
          - name: index
            description: The index of the fee within the balance transaction
          - name: amount
            description: Amount of the fee, in cents.
          - name: application
            description: ID of the Connect application that earned the fee.
          - name: currency
            description: Three-letter ISO currency code, in lowercase.
          - name: description
            description: An arbitrary string attached to the object. Often useful for displaying to users.
          - name: type
            description: Type of the fee, can be application_fee, stripe_fee or tax.

      - name: payment_intent
        identifier: "{{ var('stripe_payment_intent_identifier', 'payment_intent')}}"
        description: A Payment Intent guides you through the process of collecting a payment from your customer.
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: amount
            description: Amount intended to be collected by this PaymentIntent. A positive integer representing how much to charge in the smallest currency unit (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency)
          - name: amount_capturable
            description: Amount that can be captured from this PaymentIntent.
          - name: amount_received
            description: Amount that was collected by this PaymentIntent.
          - name: application
            description: ID of the Connect application that created the PaymentIntent.
          - name: application_fee_amount
            description: The amount of the application fee (if any) for the resulting payment.
          - name: canceled_at
            description: Populated when status is canceled, this is the time at which the PaymentIntent was canceled.
          - name: cancellation_reason
            description: Reason for cancellation of this PaymentIntent, either user-provided (duplicate, fraudulent, requested_by_customer, or abandoned) or generated by Stripe internally (failed_invoice, void_invoice, or automatic).
          - name: capture_method
            description: Controls when the funds will be captured from the customer’s account.
          - name: confirmation_method
            description: Whether confirmed automatically or manually
          - name: currency
            description: Three-letter ISO currency code, in lowercase.
          - name: customer_id
            description: ID of the Customer this PaymentIntent belongs to, if one exists.
          - name: description
            description: An arbitrary string attached to the object. Often useful for displaying to users.
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: payment_method_id
            description: ID of the payment method used in this PaymentIntent.
          - name: receipt_email
            description: Email address that the receipt for the resulting payment will be sent to.
          - name: statement_descriptor
            description: For non-card charges, you can use this value as the complete description that appears on your customers’ statements.
          - name: status
            description: Status of this PaymentIntent, one of requires_payment_method, requires_confirmation, requires_action, processing, requires_capture, canceled, or succeeded.
          - name: livemode
            description: Indicates if this is a test payment intent.

      - name: payment_method_card
        identifier: "{{ var('stripe_payment_method_card_identifier', 'payment_method_card')}}"
        description: Table with the relationships between a payment method and a card
        columns:
          - name: payment_method_id
            description: ID of the payment method
          - name: brand
            description: Card brand. Can be American Express, Diners Club, Discover, JCB, MasterCard, UnionPay, Visa, or Unknown.
          - name: funding
            description: Card funding type. Can be credit, debit, prepaid, or unknown.
          - name: charge_id
            description: ID of the charge that this card belongs to.
          - name: type
            description: The type of the payment method.
          - name: wallet_type
            description: The type of the card wallet, one of amex_express_checkout, apple_pay, google_pay, masterpass, samsung_pay, or visa_checkout. An additional hash is included on the Wallet subhash with a name matching this value. It contains additional information specific to the card wallet type.

      - name: payment_method
        identifier: "{{ var('stripe_payment_method_identifier', 'payment_method')}}"
        description: PaymentMethod objects represent your customer's payment instruments. They can be used with PaymentIntents to collect payments or saved to Customer objects to store instrument details for future payments.
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: created
            description: '{{ doc("created") }}'
          - name: customer_id
            description: The ID of the Customer to which this PaymentMethod is saved. This will not be set when the PaymentMethod has not been saved to a Customer.
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: type
            description: The type of the PaymentMethod. An additional hash is included on the PaymentMethod with a name matching this value. It contains additional information specific to the PaymentMethod type.
          - name: livemode
            description: Indicates if this is a test payment method.

      - name: payout
        identifier: "{{ var('stripe_payout_identifier', 'payout')}}"
        description: A Payout object is created when you receive funds from Stripe, or when you initiate a payout to either a bank account or debit card of a connected Stripe account.
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: amount
            description: Amount (in cents) to be transferred to your bank account or debit card.
          - name: arrival_date
            description: Date the payout is expected to arrive in the bank. This factors in delays like weekends or bank holidays.
          - name: automatic
            description: true if the payout was created by an automated payout schedule, and false if it was requested manually.
          - name: balance_transaction_id
            description: ID of the balance transaction that describes the impact of this payout on your account balance.
          - name: created
            description: '{{ doc("created") }}'
          - name: currency
            description: Three-letter ISO currency code, in lowercase.
          - name: description
            description: An arbitrary string attached to the object. Often useful for displaying to users.
          - name: destination_bank_account_id
            description: ID of the bank account the payout was sent to.
          - name: destination_card_id
            description: ID of the card the payout was sent to.
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: method
            description: The method used to send this payout, which can be standard or instant.
          - name: source_type
            description: The source balance this payout came from. One of card, fpx, or bank_account.
          - name: status
            description: Current status of the payout.  Can be paid, pending, in_transit, canceled or failed.
          - name: type
            description: Can be bank_account or card.
          - name: livemode
            description: Indicates if this is a test payout.

      - name: payout_balance_transaction
        identifier: "{{ var('stripe_payout_balance_transaction_identifier', 'payout_balance_transaction')}}"
        description: >
          Table that contains the complete mapping between `payout_id` and `balance_transaction_id`.
          The payout to balance_transaction relationship is 1:many.
        columns:
          - name: payout_id
            description: Unique identifier for the payout.
          - name: balance_transaction_id
            description: Unique identifier for the balance transaction.
          - name: _fivetran_synced
            description: Timestamp when the record was last synced.

      - name: refund
        identifier: "{{ var('stripe_refund_identifier', 'refund')}}"
        description: Details of transactions that have been refunded
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: amount
            description: Amount, in cents.
          - name: balance_transaction_id
            description: >
              ID of the latest balance transaction linked to this payout, describing its impact on your account balance.
              The payout to balance_transaction relationship is 1:many.
          - name: charge_id
            description: ID of the charge that was refunded.
          - name: created
            description: '{{ doc("created") }}'
          - name: currency
            description: Three-letter ISO currency code, in lowercase.
          - name: description
            description: An arbitrary string attached to the object. Often useful for displaying to users. (Available on non-card refunds only)
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: payment_intent_id
            description: ID of the payment intent associated with this refund.
          - name: reason
            description: Reason for the refund, either user-provided (duplicate, fraudulent, or requested_by_customer) or generated by Stripe internally (expired_uncaptured_charge).
          - name: receipt_number
            description: This is the transaction number that appears on email receipts sent for this refund.
          - name: status
            description: Status of the refund. For credit card refunds, this can be pending, succeeded, or failed. For other types of refunds, it can be pending, succeeded, failed, or canceled.

      - name: invoice_line_item
        identifier: "{{ var('stripe_invoice_line_item_identifier', 'invoice_line_item')}}"
        description: The different items that an invoice contains
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: invoice_id
            description: The ID of the invoice this item is a part of
          - name: invoice_item_id
            description: The ID of the invoice item this item is a part of
          - name: price_id
            description: ID of the price object this item pertains to
          - name: amount
            description: The amount, in cents.
          - name: currency
            description: Three-letter ISO currency code, in lowercase.
          - name: description
            description: An arbitrary string attached to the object. Often useful for displaying to users.
          - name: discountable
            description: If true, discounts will apply to this line item. Always false for prorations.
          - name: plan_id
            description: The ID of the plan of the subscription, if the line item is a subscription or a proration.
          - name: proration
            description: Whether this is a proration.
          - name: quantity
            description: The quantity of the subscription, if the line item is a subscription or a proration.
          - name: subscription_id
            description: The ID of the subscription that the invoice item pertains to, if any.
          - name: subscription_item_id
            description: The subscription item that generated this invoice item. Left empty if the line item is not an explicit result of a subscription.
          - name: type
            description: A string identifying the type of the source of this line item, either an invoice item or a subscription.
          - name: unique_id
            description: A unique id generated and only for old invoice line item ID's from a past version of the API. The introduction of this field resolves the pagination break issue for invoice line items, which was introduced by the [Stripe API update](https://stripe.com/docs/upgrades#2019-12-03).
          - name: livemode
            description: Indicates if this is a test invoice line item.

      - name: invoice
        identifier: "{{ var('stripe_invoice_identifier', 'invoice')}}"
        description: Invoices are statements of amounts owed by a customer, and are either generated one-off, or generated periodically from a subscription.
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: amount_due
            description: Final amount due at this time for this invoice. If the invoice’s total is smaller than the minimum charge amount, for example, or if there is account credit that can be applied to the invoice, the amount_due may be 0. If there is a positive starting_balance for the invoice (the customer owes money), the amount_due will also take that into account. The charge that gets generated for the invoice will be for the amount specified in amount_due.
          - name: amount_paid
            description: The amount, in cents, that was paid.
          - name: amount_remaining
            description: The amount remaining, in cents, that is due.
          - name: attempt_count
            description: Number of payment attempts made for this invoice, from the perspective of the payment retry schedule.
          - name: auto_advance
            description: Controls whether Stripe will perform automatic collection of the invoice. When false, the invoice’s state will not automatically advance without an explicit action.
          - name: billing_reason
            description: Indicates the reason why the invoice was created.
          - name: charge_id
            description: ID of the latest charge generated for this invoice, if any.
          - name: created
            description: '{{ doc("created") }}'
          - name: currency
            description: Three-letter ISO currency code, in lowercase.
          - name: customer_id
            description: The ID of the customer who will be billed.
          - name: description
            description: An arbitrary string attached to the object. Often useful for displaying to users. Referenced as ‘memo’ in the Dashboard.
          - name: due_date
            description: The date on which payment for this invoice is due. This value will be null for invoices where collection_method=charge_automatically.
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: number
            description: A unique, identifying string that appears on emails sent to the customer for this invoice. This starts with the customer’s unique invoice_prefix if it is specified.
          - name: paid
            description: Whether payment was successfully collected for this invoice. An invoice can be paid (most commonly) with a charge or with credit from the customer’s account balance.
          - name: receipt_number
            description: This is the transaction number that appears on email receipts sent for this invoice.
          - name: status
            description: Status of the invoice.
          - name: subscription_id
            description: The ID of the subscription that the invoice item pertains to, if any.
          - name: subtotal
            description: Total of all subscriptions, invoice items, and prorations on the invoice before any discount or tax is applied.
          - name: tax
            description: The amount of tax on this invoice. This is the sum of all the tax amounts on this invoice.
          - name: tax_percent
            description: The percent used to calculate the tax amount.
          - name: total
            description: Total after discounts and taxes.
          - name: livemode
            description: Indicates if this is a test invoice.
          - name: period_start
            description: Start of the usage period for which the invoice was created.
          - name: period_end
            description: End of the usage period for which the invoice was created.
          - name: default_payment_method_id
            description: ID of the default payment method in this invoice.
          - name: payment_intent_id
            description: ID of the PaymentIntent associated with this invoice.
          - name: subscription_id
            description: The ID of the subscription that the invoice pertains to,.
          - name: post_payment_credit_notes_amount
            description: Total amount of all post-payment credit notes issued for this invoice.
          - name: pre_payment_credit_notes_amount
            description: Total amount of all pre-payment credit notes issued for this invoice.
          - name: status_transitions_finalized_at
            description: The time that the invoice draft was finalized.
          - name: status_transitions_marked_uncollectible_at
            description: The time that the invoice was marked uncollectible.
          - name: status_transitions_paid_at
            description: The time that the invoice was paid.
          - name: status_transitions_voided_at
            description: The time that the invoice was voided.

      - name: subscription_history
        identifier: "{{ var('stripe_subscription_history_identifier', 'subscription_history')}}"
        description: Subscriptions allow you to charge a customer on a recurring basis. Please note this source table is used only on connectors setup **after** February 09, 2022.
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: status
            description: Possible values are incomplete, incomplete_expired, trialing, active, past_due, canceled, or unpaid.
          - name: billing
            description: How the invoice is billed
          - name: billing_cycle_anchor
            description: Determines the date of the first full invoice, and, for plans with month or year intervals, the day of the month for subsequent invoices.
          - name: cancel_at
            description: A date in the future at which the subscription will automatically get canceled
          - name: cancel_at_period_end
            description: Boolean indicating whether this subscription should cancel at the end of the current period.
          - name: canceled_at
            description: If the subscription has been canceled, the date of that cancellation.
          - name: created
            description: '{{ doc("created") }}'
          - name: current_period_start
            description: Start of the current period that the subscription has been invoiced for.
          - name: current_period_end
            description: End of the current period that the subscription has been invoiced for. At the end of this period, a new invoice will be created.
          - name: customer_id
            description: ID of the customer who owns the subscription.
          - name: days_until_due
            description: Number of days a customer has to pay invoices generated by this subscription. This value will be null for subscriptions where collection_method=charge_automatically.
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: start_date
            description: Date when the subscription was first created. The date might differ from the created date due to backdating.
          - name: ended_at
            description: If the subscription has ended, the date the subscription ended.
          - name: livemode
            description: Indicates if this is a test subscription.
          - name: _fivetran_active
            description: Boolean indicating if the record is the latest.
          - name: latest_invoice_id
            description: ID of the latest invoice for this subscription.
          - name: customer_id
            description: ID of customer this subscription belongs to.
          - name: default_payment_method_id
            description: ID of the default payment method for this subscription.
          - name: pending_setup_intent_id
            description: ID of the payment setup intent for this subscription.
          - name: pause_collection_behavior
            description: The payment collection behavior for this subscription while paused. One of keep_as_draft, mark_uncollectible, or void.
          - name: pause_collection_resumes_at
            description: The time after which the subscription will resume collecting payments.

      - name: subscription
        identifier: "{{ var('stripe_subscription_identifier', 'subscription')}}"
        description: Subscriptions allow you to charge a customer on a recurring basis. Please note this source table is only present in connectors setup **before** February 09, 2022.
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: status
            description: Possible values are incomplete, incomplete_expired, trialing, active, past_due, canceled, or unpaid.
          - name: billing
            description: How the invoice is billed
          - name: billing_cycle_anchor
            description: Determines the date of the first full invoice, and, for plans with month or year intervals, the day of the month for subsequent invoices.
          - name: cancel_at
            description: A date in the future at which the subscription will automatically get canceled
          - name: cancel_at_period_end
            description: Boolean indicating whether this subscription should cancel at the end of the current period.
          - name: canceled_at
            description: If the subscription has been canceled, the date of that cancellation.
          - name: created
            description: '{{ doc("created") }}'
          - name: current_period_start
            description: Start of the current period that the subscription has been invoiced for.
          - name: current_period_end
            description: End of the current period that the subscription has been invoiced for. At the end of this period, a new invoice will be created.
          - name: customer_id
            description: ID of the customer who owns the subscription.
          - name: days_until_due
            description: Number of days a customer has to pay invoices generated by this subscription. This value will be null for subscriptions where collection_method=charge_automatically.
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: start_date
            description: Date when the subscription was first created. The date might differ from the created date due to backdating.
          - name: ended_at
            description: If the subscription has ended, the date the subscription ended.
          - name: livemode
            description: Indicates if this is a test subscription.
          - name: pause_collection_behavior
            description: The payment collection behavior for this subscription while paused. One of keep_as_draft, mark_uncollectible, or void.
          - name: pause_collection_resumes_at
            description: The time after which the subscription will resume collecting payments.

      - name: subscription_item
        identifier: "{{ var('stripe_subscription_item_identifier', 'subscription_item')}}"
        description: Subscription items allow you to create customer subscriptions with more than one plan, making it easy to represent complex billing relationships.
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: plan_id
            description: The ID of the plan associated with this subscription_item.
          - name: subscription_id
            description: The ID of the subscription this item belongs to. Join key to the subscription_history table.
          - name: created
            description: Time at which the object was created
          - name: current_period_start
            description: Start of the current period that the subscription has been invoiced for.
          - name: current_period_end
            description: End of the current period that the subscription has been invoiced for. At the end of this period, a new invoice will be created.
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: quantity
            description: The quantity of the plan to which the customer is subscribed.

      - name: plan
        identifier: "{{ var('stripe_plan_identifier', 'plan')}}"
        description: Plans define the base price, currency, and billing cycle for recurring purchases of products.
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: active
            description: Whether the plan can be used for new purchases.
          - name: amount
            description: The unit amount in cents to be charged, represented as a whole integer if possible.
          - name: currency
            description: Three-letter ISO currency code, in lowercase.
          - name: interval
            description: The frequency at which a subscription is billed. One of day, week, month or year.
          - name: interval_count
            description: The number of intervals between subscription billings. For example, interval_count=3 bills every 3 months.
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: nickname
            description: A brief description of the plan, hidden from customers.
          - name: product
            description: The product whose pricing this plan determines.
          - name: livemode
            description: Indicates if this is a test plan.

      - name: credit_note
        identifier: "{{ var('stripe_credit_note_identifier', 'credit_note')}}"
        description: Credit notes are documents that decrease the amount owed on an invoice. They’re the only way to adjust the amount of a finalized invoice other than voiding and recreating the invoice.
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: amount
            description: The integer amount in cents representing the total amount of the credit note, including tax.
          - name: created
            description: '{{ doc("created") }}'
          - name: currency
            description: The currency of the charge. Three-letter ISO currency code, in lowercase.
          - name: discount_amount
            description: The integer amount in cents representing the total amount of discount that was credited.
          - name: subtotal
            description: The integer amount in cents representing the amount of the credit note, excluding tax and invoice level discounts.
          - name: total
            description: The integer amount in cents representing the total amount of the credit note, including tax and all discount.
          - name: livemode
            description: Has the value true if the object exists in live mode or the value false if the object exists in test mode.
          - name: memo
            description: Customer-facing text that appears on the credit note PDF.
          - name: metadata
            description: Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
          - name: number
            description: A unique number that identifies this particular credit note and appears on the PDF of the credit note and its associated invoice.
          - name: pdf
            description: The link to download the PDF of the credit note.
          - name: reason
            description: Reason for issuing this credit note, one of duplicate, fraudulent, order_change, or product_unsatisfactory
          - name: status
            description: Status of this credit note, one of issued or void. Learn more about voiding credit notes.
          - name: type
            description: Type of this credit note, one of pre_payment or post_payment. A pre_payment credit note means it was issued when the invoice was open. A post_payment credit note means it was issued when the invoice was paid.
          - name: voided_at
            description: The time that the credit note was voided.
          - name: customer_balance_transaction
            description: Customer balance transaction related to this credit note.
          - name: invoice_id
            description: The id of the invoice associated with this credit note.
          - name: refund_id
            description: The id of the refund associated with this credit note.

      - name: credit_note_line_item
        identifier: "{{ var('stripe_credit_note_line_item_identifier', 'credit_note_line_item')}}"
        description: The different items that a credit note contains.
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: credit_note_id
            description: The ID of the credit note this item is a part of.
          - name: amount
            description: The integer amount in cents representing the gross amount being credited for this line item, excluding (exclusive) tax and discounts.
          - name: discount_amount
            description: The integer amount in cents representing the discount being credited for this line item.
          - name: description
            description: Description of the item being credited.
          - name: livemode
            description: Has the value true if the object exists in live mode or the value false if the object exists in test mode.
          - name: quantity
            description: The number of units of product being credited.
          - name: type
            description: The type of the credit note line item, one of invoice_line_item or custom_line_item. When the type is invoice_line_item there is an additional invoice_line_item property on the resource the value of which is the id of the credited line item on the invoice.
          - name: unit_amount
            description: The cost of each unit of product being credited.
          - name: unit_amount_decimal
            description: Same as unit_amount, but contains a decimal value with at most 12 decimal places.

      - name: price
        identifier: "{{ var('stripe_price_identifier', 'price')}}"
        description: Prices define the unit cost, currency, and (optional) billing cycle for both recurring and one-time purchases of products.
        config:
          freshness: null
        columns:
          - name: active
            description: Whether the price can be used for new purchases.
          - name: billing_scheme
            description: Describes how to compute the price per period. Either per_unit or tiered. per_unit indicates that the fixed amount (specified in unit_amount or unit_amount_decimal) will be charged per unit in quantity (for prices with usage_type=licensed), or per unit of total usage (for prices with usage_type=metered). tiered indicates that the unit pricing will be computed using a tiering strategy as defined using the tiers and tiers_mode attributes.
          - name: created
            description: '{{ doc("created") }}'
          - name: currency
            description: Three-letter ISO currency code, in lowercase. Must be a supported currency.
          - name: id
            description: Unique identifier for the object.
          - name: invoice_item_id
            description: The ID of the invoice item this record is a part of.
          - name: is_deleted
            description: Whether record has been deleted.
          - name: livemode
            description: Has the value true if the object exists in live mode or the value false if the object exists in test mode.
          - name: lookup_key
            description: A lookup key used to retrieve prices dynamically from a static string. This may be up to 200 characters.
          - name: metadata
            description: Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
          - name: nickname
            description: A brief description of the price, hidden from customers.
          - name: product_id
            description: The ID of the product this price is associated with.
          - name: recurring_aggregate_usage
            description: Specifies a usage aggregation strategy for prices of usage_type=metered. Allowed values are sum for summing up all usage during a period, last_during_period for using the last usage record reported within a period, last_ever for using the last usage record ever (across period bounds) or max which uses the usage record with the maximum reported usage during a period. Defaults to sum.
          - name: recurring_interval
            description: Specifies billing frequency. Either day, week, month or year.
          - name: recurring_interval_count
            description: The number of intervals between subscription billings. For example, interval=month and interval_count=3 bills every 3 months. Maximum of one year interval allowed (1 year, 12 months, or 52 weeks).
          - name: recurring_usage_type
            description: Configures how the quantity per period should be determined. Can be either metered or licensed. licensed automatically bills the quantity set when adding it to a subscription. metered aggregates the total usage based on usage records. Defaults to licensed.
          - name: tiers_mode
            description: Defines if the tiering price should be graduated or volume based. In volume-based tiering, the maximum quantity within a period determines the per unit price. In graduated tiering, pricing can change as the quantity grows.
          - name: transform_quantity_divide_by
            description: Divide usage by this number. Transform Quantity applies a transformation to the reported usage or set quantity before computing the amount billed. Cannot be combined with tiers.
          - name: transform_quantity_round
            description: After division, either round the result up or down. Transform Quantity applies a transformation to the reported usage or set quantity before computing the amount billed. Cannot be combined with tiers.
          - name: type
            description: One of one_time or recurring depending on whether the price is for a one-time purchase or a recurring (subscription) purchase.
          - name: unit_amount
            description: The unit amount in cents to be charged, represented as a whole integer if possible. Only set if billing_scheme=per_unit.
          - name: unit_amount_decimal
            description: The unit amount in cents to be charged, represented as a decimal string with at most 12 decimal places. Only set if billing_scheme=per_unit.

      - name: account
        identifier: "{{ var('stripe_account_identifier', 'account')}}"
        description: Prices define the unit cost, currency, and (optional) billing cycle for both recurring and one-time purchases of products.
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: business_profile_name
            description: The customer-facing business name.
          - name: business_type
            description: The business type.
          - name: business_profile_mcc
            description: The merchant category code for the account. MCCs are used to classify businesses based on the goods or services they provide.
          - name: charges_enabled
            description: Whether the account can create live charges.
          - name: company_address_city
            description: City, district, suburb, town, or village.
          - name: company_address_country
            description: Two-letter country code (ISO 3166-1 alpha-2).
          - name: company_address_line_1
            description: Address line 1 (e.g., street, PO Box, or company name).
          - name: company_address_line_2
            description: Address line 2 (e.g., apartment, suite, unit, or building).
          - name: company_address_postal_code
            description: ZIP or postal code.
          - name: company_address_state
            description: State, county, province, or region.
          - name: company_name
            description: The company’s legal name.
          - name: company_phone
            description: The company’s phone number (used for verification).
          - name: country
            description: The account's country.
          - name: created
            description: '{{ doc("created") }}'
          - name: default_currency
            description: Three-letter ISO currency code representing the default currency for the account. This must be a currency that Stripe supports in the account’s country.
          - name: email
            description: An email address associated with the account. You can treat this as metadata; it is not used for authentication or messaging account holders.
          - name: is_deleted
            description: Boolean of whether account has been deleted. Accounts created using test-mode keys can be deleted at any time. Standard accounts created using live-mode keys cannot be deleted. Custom or Express accounts created using live-mode keys can only be deleted once all balances are zero.
          - name: metadata
            description: Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to metadata.
          - name: payouts_enabled
            description: Boolean of whether payouts are enabled.
          - name: type
            description: Account type


      - name: transfer
        identifier: "{{ var('stripe_transfer_identifier', 'transfer')}}"
        description: A Transfer object is created when you move funds between Stripe accounts as part of Connect. Before April 6, 2017, transfers also represented movement of funds from a Stripe account to a card or bank account. That has since been moved to the Payout object. The Payout object represents money moving from a Stripe account to an external account (bank or debit card). The Transfer object now only represents money moving between Stripe accounts on a Connect platform.
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: amount
            description: Amount in cents to be transferred.
          - name: amount_reversed
            description: Amount in cents reversed (can be less than the amount attribute on the transfer if a partial reversal was issued).
          - name: balance_transaction_id
            description: Balance transaction that describes the impact of this transfer on your account balance.
          - name: created
            description: Time that this record of the transfer was first created.
          - name: currency
            description: Three-letter ISO currency code, in lowercase. Must be a supported currency.
          - name: description
            description: An arbitrary string attached to the object. Often useful for displaying to users.
          - name: destination
            description: ID of the Stripe account the transfer was sent to.
          - name: destination_payment
            description: If the destination is a Stripe account, the payment that the destination account received for the transfer.
          - name: destination_payment_id
            description: If the destination is a Stripe account, this will be the ID of the payment that the destination account received for the transfer.
          - name: livemode
            description: Indicates if this is a test transfer.
          - name: metadata
            description: Custom metadata added to the record, in JSON string format
          - name: reversed
            description: Boolean of whether the transfer has been fully reversed. If the transfer is only partially reversed, this attribute will still be false.
          - name: source_transaction
            description: The source transaction related to this transfer.
          - name: source_transaction_id
            description: ID of the charge or payment that was used to fund the transfer. If null, the transfer was funded from the available balance.
          - name: source_type
            description: The source balance this transfer came from. One of card, fpx, or bank_account.
          - name: transfer_group
            description: A string that identifies this transaction as part of a group. See the Connect documentation for details.

      - name: product
        identifier: "{{ var('stripe_product_identifier', 'product') }}"
        description: A product object represents an individual product to be sold, with various attributes detailing its properties and behaviors.
        config:
          freshness: null
        columns:
          - name: id
            description: Unique identifier for the object.
          - name: active
            description: Whether the product is currently available for purchase.
          - name: attributes
            description: Key-value pairs that can be attached to a product object, useful for storing additional structured information.
          - name: caption
            description: A brief explanation or description of the product for display purposes.
          - name: create
            description: Timestamp indicating when the product was created.
          - name: deactivate_on
            description: List of dates when the product will be deactivated.
          - name: description
            description: The product’s description, meant to be displayable to the customer.
          - name: images
            description: A list of up to 8 URLs of images for this product, meant to be displayable to the customer.
          - name: is_deleted
            description: Indicates whether the product has been deleted.
          - name: livemode
            description: Indicates if this is a test product.
          - name: name
            description: The product’s name, meant to be displayable to the customer.
          - name: shippable
            description: Whether this product is shipped (i.e., physical goods).
          - name: statement_descriptor
            description: Extra information about a product which will appear on your customer’s credit card statement.
          - name: type
            description: The type of the product (e.g., good, service).
          - name: unit_label
            description: A label that represents units of this product, included in receipts and invoices.
          - name: updated
            description: Time at which the object was last updated, measured in seconds since the Unix epoch.
          - name: url
            description: A URL of a publicly-accessible webpage for this product.


      - name: discount
        identifier: "{{ var('stripe_discount_identifier', 'discount') }}"
        description: A discount represents the actual application of a coupon or promotion code. It contains information about when the discount began, when it will end, and what it is applied to.
        config:
          freshness: null
        columns:
          - name: id
            description: The ID of the discount object.
          - name: type
            description: String representing the object’s type.
          - name: type_id
            description: Identifier of the related object type (e.g., coupon ID, promotion code).
          - name: amount
            description: The amount of discount applied.
          - name: checkout_session_id
            description: The Checkout session that this discount is applied to, if it is applied to a particular session in payment mode.
          - name: checkout_session_line_item_id
            description: The ID of the specific line item within the checkout session that the discount is applied to.
          - name: coupon_id
            description: The ID of the coupon applied to create this discount.
          - name: credit_note_line_item_id
            description: The ID of the credit note line item associated with this discount.
          - name: customer_id
            description: The ID of the customer associated with this discount.
          - name: end
            description: If the coupon has a duration of repeating, the date that this discount will end. If the coupon has a duration of once or forever, this attribute will be null.
          - name: invoice_id
            description: The invoice that the discount’s coupon was applied to, if it was applied directly to a particular invoice.
          - name: invoice_item_id
            description: The invoice item id (or invoice line item id for invoice line items of type=‘subscription’) that the discount’s coupon was applied to, if it was applied directly to a particular invoice item or invoice line item.
          - name: promotion_code
            description: The promotion code applied to create this discount.
          - name: start
            description: The date that the coupon was applied.
          - name: subscription_id
            description: The subscription that this coupon is applied to, if it is applied to a particular subscription.
```

</details>

3. Add the following variable configuration to your `dbt_project.yml`:

```yml
# dbt_project.yml
vars:
  stripe:
    has_defined_sources: true
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
    stripe:
        stripe__using_livemode: false  # Default = true
```
#### Including sub Invoice Line Items
By default, this package will filter out any records from the `invoice_line_item` source table which include the string `sub_`. This is due to a legacy Stripe issue where `sub_` records were found to be duplicated. However, if you highly utilize these records you may wish they be included in the final output of the `stg_stripe__invoice_line_item` model. To do, so you may include the below variable configuration in your root `dbt_project.yml`:
```yml
vars:
    stripe:
        stripe__using_invoice_line_sub_filter: false # Default = true
```

#### Pivoting out Metadata Properties
Oftentimes you may have custom fields within your source tables that is stored as a JSON object that you wish to pass through. By leveraging the `metadata` variable, this package will pivot out fields into their own columns within the respective staging models. The metadata variables accept dictionaries in addition to strings.

Additionally, you may `alias` your field if you happen to be using a reserved word as a metadata field, any otherwise incompatible name, or just wish to rename your field. Below are examples of how you would add the respective fields.

The `metadata` JSON field is present within the `customer`, `charge`, `card`, `invoice`, `invoice_line_item`, `payment_intent`, `payment_method`, `payout`, `plan`, `price`, `refund`, `subscription`, and `subscription_item` source tables. To pivot these fields out and include in the respective downstream staging model, add the relevant variable(s) to your root `dbt_project.yml` file like below.

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
  stripe__subscription_item_metadata:
    - name: 568
      alias: five_six_eight

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

#### Passing Through Additional Fields
This package includes all source columns defined in the macros folder. You can add more columns using our pass-through column variables. These variables allow for the pass-through fields to be aliased (`alias`) and casted (`transform_sql`) if desired, but not required. Datatype casting is configured via a sql snippet within the `transform_sql` key. You may add the desired sql while omitting the `as field_name` at the end and your custom pass-though fields will be casted accordingly. Use the below format for declaring the respective pass-through variables:

```yml
# dbt_project.yml

vars:
  stripe:
    card_pass_through_columns:
      - name: "description"
      - name: "iin"
      - name: "issuer"
        alias: "card_issuer"  # optional: define an alias for the column 
        transform_sql: "cast(card_issuer as string)" # optional: apply transformation to column. must reference the alias if provided
```

#### Change the build schema
By default, this package builds the stripe staging models within a schema titled (`<target_schema>` + `_stg_stripe`) in your destination. If this is not where you would like your stripe staging data to be written to, add the following configuration to your root `dbt_project.yml` file:

```yml
models:
    stripe:
      +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
      staging:
        +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
```

#### Change the source table references
If an individual source table has a different name than the package expects, add the table name as it appears in your destination to the respective variable:
> IMPORTANT: See this project's [`dbt_project.yml`](https://github.com/fivetran/dbt_stripe/blob/main/dbt_project.yml) variable declarations to see the expected names.

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
