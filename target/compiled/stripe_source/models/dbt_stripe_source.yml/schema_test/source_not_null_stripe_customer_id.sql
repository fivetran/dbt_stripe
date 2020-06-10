



select count(*) as validation_errors
from `dbt-package-testing`.`stripe`.`customer`
where id is null

