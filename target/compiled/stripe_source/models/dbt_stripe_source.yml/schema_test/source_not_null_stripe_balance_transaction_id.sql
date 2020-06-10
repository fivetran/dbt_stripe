



select count(*) as validation_errors
from `dbt-package-testing`.`stripe`.`balance_transaction`
where id is null

