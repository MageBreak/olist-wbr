-- Q4. Repeat-purchase rate = customers with 2+ orders / all customers.
-- A customer is customer_unique_id. customer_id is regenerated for EVERY order,
-- so counting by it always gives ~0% (shown in the last column as the "wrong way").
WITH per_person AS (
    SELECT customer_unique_id, COUNT(DISTINCT order_id) AS orders
    FROM mart_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1
),
per_customer_id AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS orders
    FROM mart_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1
)
SELECT
    COUNT(*)                                              AS customers,
    COUNT(*) FILTER (WHERE orders >= 2)                   AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE orders >= 2) / COUNT(*), 2) AS repeat_rate_pct,
    (SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE orders >= 2) / COUNT(*), 2)
     FROM per_customer_id)                                AS wrong_rate_using_customer_id_pct
FROM per_person;
