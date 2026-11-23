{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key=['status', 'payment_method']
    )
}}

select
    status,
    payment_method,
    total_amount,
    payment_count

from {{ ref('int_payment_status_summary') }}
