#!/bin/bash

set -euo pipefail

apt-get update
apt-get install libsasl2-dev

python3 -m venv venv
. venv/bin/activate
pip install --upgrade pip setuptools
pip install -r integration_tests/requirements.txt
mkdir -p ~/.dbt
cp integration_tests/ci/sample.profiles.yml ~/.dbt/profiles.yml

db=$1
echo `pwd`
cd integration_tests
dbt deps
dbt seed --target "$db" --full-refresh
dbt run --target "$db" --full-refresh
dbt test --target "$db"
dbt run --vars '{stripe__using_invoices: false, stripe__using_payment_method: false, stripe__using_subscriptions: false, stripe_timezone: "America/New_York", stripe__using_subscription_history: false, stripe__using_price: false, stripe__amount_divide: false}' --target "$db"
dbt test --target "$db"

dbt run-operation fivetran_utils.drop_schemas_automation --target "$db"
