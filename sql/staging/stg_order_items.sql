-- One row per item in an order. Money as DECIMAL, never float.
CREATE OR REPLACE TABLE stg_order_items AS
SELECT
    order_id,
    CAST(order_item_id AS INTEGER)       AS order_item_id,
    product_id,
    seller_id,
    CAST(price         AS DECIMAL(12,2)) AS price,
    CAST(freight_value AS DECIMAL(12,2)) AS freight_value
FROM raw_order_items;
