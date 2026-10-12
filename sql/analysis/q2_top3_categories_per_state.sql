-- Q2. Top 3 product categories per customer state, by revenue.
-- Item grain: each item joins to exactly one order and one product (many-to-one, no fan-out).
-- DENSE_RANK: ties share a rank and the next rank isn't skipped (1,1,2) -> a tie can return >3 rows.
WITH category_revenue AS (
    SELECT m.customer_state,
           p.category,
           SUM(i.price + i.freight_value) AS revenue
    FROM stg_order_items i
    JOIN mart_orders  m ON i.order_id   = m.order_id
    JOIN stg_products p ON i.product_id = p.product_id
    WHERE m.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1, 2
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY customer_state ORDER BY revenue DESC) AS rnk
    FROM category_revenue
)
SELECT customer_state, rnk, category, revenue
FROM ranked
WHERE rnk <= 3
ORDER BY customer_state, rnk;
