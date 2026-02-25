{{ config(materialized='incremental', unique_key='order_id') }}

SELECT
    order_id,
    order_ts,
    customer_id,
    customer_region,
    device,
    status
FROM {{ source('core','ONLINE_ORDERS') }}

{% if is_incremental() %}
WHERE order_ts > (SELECT MAX(order_ts) FROM {{ this }})
{% endif %}