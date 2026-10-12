-- Part D: Weekly Business Review metrics, by purchase week (Jan 2017 - Aug 2018).
-- Edges excluded: 2016 is near-empty; Sep-Oct 2018 orders were still in transit at the data cut.
-- On-time = delivered on or before the promised calendar day (delivery_delay_days <= 0), same rule as is_late.
WITH valid AS (
    SELECT *
    FROM mart_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
      AND purchased_at >= TIMESTAMP '2017-01-01'
      AND purchased_at <  TIMESTAMP '2018-09-01'
)
SELECT
    CAST(DATE_TRUNC('week', purchased_at) AS DATE)                         AS week,
    COUNT(*)                                                                AS orders,
    SUM(order_value)                                                        AS gmv,
    COUNT(*) FILTER (WHERE delivery_delay_days <= 0 AND review_score >= 4)  AS happy_deliveries,  -- North Star
    ROUND(100.0 * COUNT(*) FILTER (WHERE delivery_delay_days <= 0)
          / NULLIF(COUNT(delivered_at), 0), 1)                              AS on_time_rate_pct,
    ROUND(AVG(DATE_DIFF('day', purchased_at, estimated_delivery_at)), 1)    AS avg_promised_days  -- guardrail
FROM valid
GROUP BY 1
ORDER BY 1;
