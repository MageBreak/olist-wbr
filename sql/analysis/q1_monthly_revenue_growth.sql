-- Q1. Month-over-month revenue and growth %.
-- Month spine: Olist has NO orders in Nov 2016. Without a spine, LAG would compare
-- Dec 2016 to Oct 2016 and silently call it "month-over-month".
WITH bounds AS (
    SELECT MIN(purchase_month) AS first_month, MAX(purchase_month) AS last_month
    FROM mart_orders
),
months AS (
    SELECT UNNEST(generate_series(first_month, last_month, INTERVAL 1 MONTH)) AS month
    FROM bounds
),
monthly AS (
    SELECT purchase_month AS month, COUNT(*) AS orders, SUM(order_value) AS revenue
    FROM mart_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1
),
filled AS (
    SELECT m.month, COALESCE(x.orders, 0) AS orders, COALESCE(x.revenue, 0) AS revenue
    FROM months m
    LEFT JOIN monthly x ON m.month = x.month
)
SELECT
    CAST(month AS DATE)                              AS month,
    orders,
    revenue,
    LAG(revenue) OVER (ORDER BY month)               AS prev_month_revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
          / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 1) AS mom_growth_pct
FROM filled
ORDER BY month;
