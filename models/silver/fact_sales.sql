{{ config(
    materialized='incremental',
    unique_key='src_hash',
    on_schema_change='sync_all_columns'
) }}

WITH online_sales AS (

    SELECT
        'ONLINE' AS source_type,
        o.order_id AS source_doc_id,
        i.line_no AS source_line_nbr,
        o.order_ts AS sales_ts,
        DATE(o.order_ts) AS sales_date,
        99 AS store_id,
        o.customer_id,
        o.customer_region,
        o.device,
        o.status,
        i.product_id,
        i.product_name,
        i.category,
        i.qty,
        i.unit_price,
        i.qty * i.unit_price AS gross_amount,
        NULL AS discount_pct,
        0 AS discount_amount,
        i.qty * i.unit_price AS net_amount,
        NULL AS payment_method,
        IFF(o.status='CANCELLED', TRUE, FALSE) AS is_cancelled,
        CURRENT_TIMESTAMP() AS load_dts,
        'ONLINE|' || o.order_id || '|' || i.product_id || '|' || i.line_no AS src_hash
    FROM {{ ref('stg_online_orders') }} o
    JOIN {{ ref('stg_online_items') }} i
      ON o.order_id = i.order_id
),

pos_sales AS (

    SELECT
        'POS' AS source_type,
        transaction_id AS source_doc_id,
        1 AS source_line_nbr,
        transaction_ts AS sales_ts,
        DATE(transaction_ts) AS sales_date,
        store_id,
        101 AS customer_id,
        'NA' AS customer_region,
        'NA' AS device,
        'COMPLETED' AS status,
        product_id,
        'UNKNOWN' AS product_name,
        'UNKNOWN' AS category,
        quantity AS qty,
        unit_price,
        quantity * unit_price AS gross_amount,
        discount_pct,
        ROUND((quantity * unit_price) * (discount_pct / 100), 2) AS discount_amount,
        net_amount,
        payment_method,
        FALSE AS is_cancelled,
        CURRENT_TIMESTAMP() AS load_dts,
        'POS|' || transaction_id || '|' || product_id AS src_hash
    FROM {{ ref('stg_pos_sales') }}
)

SELECT * FROM online_sales
UNION ALL
SELECT * FROM pos_sales

{% if is_incremental() %}
WHERE src_hash NOT IN (SELECT src_hash FROM {{ this }})
{% endif %}