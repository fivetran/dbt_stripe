



select count(*) as validation_errors
from `dbt-package-testing`.`stripe`.`card`
where id is null

