



select count(*) as validation_errors
from (

    select
        id

    from `dbt-package-testing`.`stripe`.`payment_method`
    where id is not null
    group by id
    having count(*) > 1

) validation_errors

