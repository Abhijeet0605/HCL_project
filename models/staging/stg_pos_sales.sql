{{ config(materialized='incremental', unique_key='transaction_id||product_id') }}

SELECT
    transaction_id,
    transaction_ts,
    store_id,
    product_id,
    quantity,
    unit_price,
    discount_pct,
    net_amount,
    payment_method
FROM {{ source('raw','STORE_SALES') }}

{% if is_incremental() %}
WHERE transaction_ts > (SELECT MAX(transaction_ts) FROM {{ this }})
{% endif %}