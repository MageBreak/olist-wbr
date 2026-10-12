-- Where do late orders lose time? Seller leg (purchase -> carrier handover) vs carrier leg (handover -> customer).
-- ship_by = seller's handover deadline (latest across the order's items).
WITH limits AS (
    SELECT order_id, MAX(TRY_CAST(shipping_limit_date AS TIMESTAMP)) AS ship_by
    FROM raw_order_items
    GROUP BY order_id
)
SELECT
    CASE WHEN m.is_late THEN 'late' ELSE 'on time / early' END AS delivery,
    COUNT(*) AS orders,
    ROUND(100.0 * AVG(CASE WHEN o.shipped_at > l.ship_by THEN 1 ELSE 0 END), 1) AS pct_seller_missed_handover,
    ROUND(AVG(DATE_DIFF('day', m.purchased_at, o.shipped_at)), 1)  AS avg_days_to_handover,
    ROUND(AVG(DATE_DIFF('day', o.shipped_at, m.delivered_at)), 1)  AS avg_days_in_transit
FROM mart_orders m
JOIN stg_orders o USING (order_id)
JOIN limits     l USING (order_id)
WHERE m.order_status = 'delivered' AND m.delivered_at IS NOT NULL
GROUP BY 1
ORDER BY 1;
