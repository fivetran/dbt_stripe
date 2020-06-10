



select count(*) as validation_errors
from `dbt-package-testing`.`stripe`.`refund`
where id is null

