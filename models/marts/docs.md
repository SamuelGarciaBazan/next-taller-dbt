{% docs orders_status %}

Orders can be one of the following statuses:

| status         | description                                                                                                            |
|----------------|------------------------------------------------------------------------------------------------------------------------|
| placed         | The order has been placed but has not yet left the warehouse                                                           |
| shipped        | The order has ben shipped to the customer and is currently in transit                                                  |
| completed      | The order has been received by the customer                                                                            |
| return_pending | The customer has indicated that they would like to return the order, but it has not yet been received at the warehouse |
| returned       | The order has been returned by the customer and received at the warehouse                                              |


{% enddocs %}

{% docs payment_status_summary %}

This model summarizes the amount received for each combination of order status and payment method.

It has one row per `status` and `payment_method` pair. The aggregation logic is implemented in
the intermediate model `int_payment_status_summary`, which joins payments to their related orders:

`stg_payments.order_id` -> `stg_orders.order_id`

The model is incremental with a delete-and-insert strategy. The composite key is
`status + payment_method`; dbt updates existing combinations and removes stale combinations
during a full refresh. `total_amount` is measured in AUD and `payment_count` is the number of
payment records represented by the aggregate.

{% enddocs %}

{% docs payment_method %}

The payment method used for an order:

| payment_method | description |
|----------------|-------------|
| credit_card | Payment made with a credit card |
| coupon | Payment paid using a coupon |
| bank_transfer | Payment made by bank transfer |
| gift_card | Payment made with a gift card |

{% enddocs %}
