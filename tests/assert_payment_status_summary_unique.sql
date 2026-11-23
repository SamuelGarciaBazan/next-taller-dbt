select
    status,
    payment_method,
    count(*) as row_count

from {{ ref('payment_status_summary') }}

group by
    status,
    payment_method

having count(*) > 1
