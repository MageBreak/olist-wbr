-- OWN CHECK: status says 'delivered' but there's no delivery timestamp.
-- These would silently break the delivery-delay analysis (Part C Q5).
SELECT order_id, order_status, delivered_at
FROM stg_orders
WHERE order_status = 'delivered' AND delivered_at IS NULL
