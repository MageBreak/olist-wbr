-- Orphan orders: customer_id has no matching customer record.
SELECT o.order_id, o.customer_id
FROM stg_orders o
LEFT JOIN stg_customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
