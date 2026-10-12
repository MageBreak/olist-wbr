-- Q5. Average delivery delay vs the estimated date, and how it relates to review score.
-- delay = delivered - estimated (days). Negative = early, positive = late.
-- Only delivered orders with a delivery date and a review (the 8 flagged orders drop out here).
-- ROLLUP adds a final "all orders" row = the overall average delay.
WITH delivered AS (
    SELECT delivery_delay_days,
           review_score,
           CASE
               WHEN delivery_delay_days <= -10 THEN '1. Early 10+ days'
               WHEN delivery_delay_days <   0  THEN '2. Early 1-9 days'
               WHEN delivery_delay_days =   0  THEN '3. On the promised day'
               WHEN delivery_delay_days <=  7  THEN '4. Late 1-7 days'
               ELSE                                '5. Late 8+ days'
           END AS delay_bucket
    FROM mart_orders
    WHERE order_status = 'delivered'
      AND delivered_at IS NOT NULL
      AND review_score IS NOT NULL
)
SELECT
    COALESCE(delay_bucket, '6. ALL DELIVERED ORDERS')  AS delay_bucket,
    COUNT(*)                                           AS orders,
    ROUND(AVG(delivery_delay_days), 1)                 AS avg_delay_days,
    ROUND(AVG(review_score), 2)                        AS avg_review_score,
    ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 1) AS pct_1_or_2_star
FROM delivered
GROUP BY ROLLUP (delay_bucket)
ORDER BY 1;
