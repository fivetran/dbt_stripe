



select count(*) as validation_errors
from "redshift-test-kristin"."stripe"."payment_method"
where id is null

