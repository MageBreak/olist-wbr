-- OWN CHECK (grain): staging dedups reviews; this proves the dedup worked.
SELECT order_id, COUNT(*) AS reviews
FROM stg_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
