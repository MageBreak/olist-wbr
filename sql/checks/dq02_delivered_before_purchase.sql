-- Delivered before it was purchased: physically impossible, so it's a data error.
SELECT order_id, purchased_at, delivered_at
FROM stg_orders
WHERE delivered_at < purchased_at
