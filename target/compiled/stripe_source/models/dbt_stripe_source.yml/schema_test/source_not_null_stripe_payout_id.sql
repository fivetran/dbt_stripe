



select count(*) as validation_errors
from `dbt-package-testing`.`stripe`.`payout`
where id is null

