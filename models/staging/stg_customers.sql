{{ config(materialized='table') }}

SELECT
    customer_id,
    region
FROM {{ source('raw','CUSTOMERS') }}