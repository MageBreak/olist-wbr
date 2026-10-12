-- Every order must appear exactly once with a non-null id.
SELECT order_id, COUNT(*) AS copies
FROM stg_orders
GROUP BY order_id
HAVING order_id IS NULL OR COUNT(*) > 1
