



select count(*) as validation_errors
from `dbt-package-testing`.`stripe`.`payment_method`
where id is null

