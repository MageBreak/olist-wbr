-- Late rate per customer state (states with 500+ delivered orders), plus each state's share of ALL late orders.
-- Total is computed over every state, so small states don't distort the share.
WITH delivered AS (
    SELECT * FROM mart_orders
    WHERE order_status = 'delivered' AND delivered_at IS NOT NULL
),
totals AS (
    SELECT COUNT(*) FILTER (WHERE is_late) AS all_late FROM delivered
)
SELECT
    customer_state,
    COUNT(*)                                                         AS orders,
    COUNT(*) FILTER (WHERE is_late)                                  AS late_orders,
    ROUND(100.0 * AVG(CASE WHEN is_late THEN 1 ELSE 0 END), 1)       AS late_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_late) / (SELECT all_late FROM totals), 1) AS share_of_all_late_pct,
    ROUND(AVG(review_score), 2)                                      AS avg_review
FROM delivered
GROUP BY 1
HAVING COUNT(*) >= 500
ORDER BY late_rate_pct DESC;
