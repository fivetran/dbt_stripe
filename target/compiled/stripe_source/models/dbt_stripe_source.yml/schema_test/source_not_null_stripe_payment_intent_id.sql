



select count(*) as validation_errors
from `dbt-package-testing`.`stripe`.`payment_intent`
where id is null

