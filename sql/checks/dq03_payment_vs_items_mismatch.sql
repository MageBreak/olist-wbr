-- Amount paid vs (item price + freight), per order, off by more than R$1 (absorbs cent rounding).
-- Aggregate BOTH sides to one row per order before joining, or the join double-counts (trap 2).
WITH items AS (
    SELECT order_id, SUM(price + freight_value) AS items_total
    FROM stg_order_items GROUP BY order_id
),
pays AS (
    SELECT order_id, SUM(payment_value) AS paid_total
    FROM stg_payments GROUP BY order_id
)
SELECT i.order_id, i.items_total, p.paid_total, p.paid_total - i.items_total AS diff
FROM items i
JOIN pays p USING (order_id)
WHERE ABS(p.paid_total - i.items_total) > 1.00
