with payments as (

    select
        order_id,
        payment_method,
        amount

    from {{ ref('stg_payments') }}

),

orders as (

    select
        order_id,
        status

    from {{ ref('stg_orders') }}

),

payment_status as (

    select
        orders.status,
        payments.payment_method,
        sum(payments.amount) as total_amount,
        count(*) as payment_count

    from payments

    inner join orders
        on payments.order_id = orders.order_id

    group by
        orders.status,
        payments.payment_method

)

select *
from payment_status
