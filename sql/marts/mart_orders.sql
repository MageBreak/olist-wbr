-- One row per order. Analysis-ready: totals, delivery timing, review, DQ flags.
-- Rule: aggregate every child table to order grain FIRST, then LEFT JOIN onto orders (no fan-out).
CREATE OR REPLACE TABLE mart_orders AS
WITH items AS (
    SELECT order_id,
           COUNT(*)           AS item_count,
           SUM(price)         AS items_value,
           SUM(freight_value) AS freight_value
    FROM stg_order_items
    GROUP BY order_id
),
pays AS (
    SELECT order_id,
           SUM(payment_value) AS paid_total
    FROM stg_payments
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,                                   -- the real person (repeat-purchase analysis)
    c.state                                AS customer_state,
    o.order_status,
    o.purchased_at,
    CAST(o.purchased_at AS DATE)           AS purchase_date,
    DATE_TRUNC('month', o.purchased_at)    AS purchase_month,
    o.delivered_at,
    o.estimated_delivery_at,

    COALESCE(i.item_count, 0)              AS item_count,
    COALESCE(i.items_value, 0)             AS items_value,
    COALESCE(i.freight_value, 0)           AS freight_value,
    COALESCE(i.items_value, 0) + COALESCE(i.freight_value, 0) AS order_value,
    p.paid_total,

    -- Delivery: positive = days late vs promise, negative = days early. NULL if not delivered.
    DATE_DIFF('day', o.estimated_delivery_at, o.delivered_at) AS delivery_delay_days,
    DATE_DIFF('day', o.estimated_delivery_at, o.delivered_at) > 0 AS is_late,
    DATE_DIFF('day', o.purchased_at, o.delivered_at)          AS delivery_days,

    r.review_score,

    -- DQ flags (see sql/checks): rows are kept, not dropped
    COALESCE(ABS(p.paid_total - (i.items_value + i.freight_value)) > 1.00, FALSE) AS flag_payment_mismatch,
    (o.order_status = 'delivered' AND o.delivered_at IS NULL)                      AS flag_missing_delivery_date
FROM stg_orders o
LEFT JOIN stg_customers c ON o.customer_id = c.customer_id
LEFT JOIN items         i ON o.order_id    = i.order_id
LEFT JOIN pays          p ON o.order_id    = p.order_id
LEFT JOIN stg_reviews   r ON o.order_id    = r.order_id;
