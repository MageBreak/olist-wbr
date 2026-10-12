-- Late orders: share of all delivered orders vs share of all 1-2 star reviews.
SELECT
    ROUND(100.0 * AVG(CASE WHEN is_late THEN 1 ELSE 0 END), 1) AS pct_orders_late,
    ROUND(100.0 * SUM(CASE WHEN is_late AND review_score <= 2 THEN 1 ELSE 0 END)
          / SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 1) AS pct_of_bad_reviews_from_late
FROM mart_orders
WHERE order_status = 'delivered' AND delivered_at IS NOT NULL AND review_score IS NOT NULL;
