



select count(*) as validation_errors
from `dbt-package-testing`.`stripe`.`charge`
where id is null

