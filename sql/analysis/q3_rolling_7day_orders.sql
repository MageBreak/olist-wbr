-- Q3. 7-day rolling average of daily order count.
-- Day spine again: ROWS BETWEEN 6 PRECEDING counts ROWS, not days. If a zero-order day
-- is missing from the table, the "7-day" window silently stretches to 8+ calendar days.
-- Note: the first 6 days average over fewer than 7 days (not enough history yet).
WITH bounds AS (
    SELECT CAST(MIN(purchase_date) AS TIMESTAMP) AS d0,
           CAST(MAX(purchase_date) AS TIMESTAMP) AS d1
    FROM mart_orders
),
days AS (
    SELECT CAST(UNNEST(generate_series(d0, d1, INTERVAL 1 DAY)) AS DATE) AS day
    FROM bounds
),
daily AS (
    SELECT purchase_date AS day, COUNT(*) AS orders
    FROM mart_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1
),
filled AS (
    SELECT d.day, COALESCE(x.orders, 0) AS orders
    FROM days d
    LEFT JOIN daily x ON d.day = x.day
)
SELECT
    day,
    orders,
    ROUND(AVG(orders) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 1) AS orders_7d_avg
FROM filled
ORDER BY day;
