{{ config(materialized='incremental', unique_key='order_id||line_no') }}

SELECT
    order_id,
    line_no,
    product_id,
    product_name,
    category,
    unit_price,
    qty
FROM {{ source('core','ONLINE_ORDER_ITEMS') }}

{% if is_incremental() %}
WHERE order_id > (SELECT MAX(order_id) FROM {{ this }})
{% endif %}