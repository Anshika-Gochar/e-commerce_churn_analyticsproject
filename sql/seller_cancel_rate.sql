
-- ================================================
-- SELLER HEALTH — CANCEL RATE (RTO PROXY)
-- Cancel rate used as proxy for RTO
-- since Olist dataset has no explicit RTO field
-- ================================================

WITH seller_order_stats AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT o.order_id)                          AS total_orders,
        SUM(CASE WHEN o.order_status = 'canceled' 
                 THEN 1 ELSE 0 END)                         AS canceled_orders,
        AVG(r.review_score)                                 AS avg_review_score,
        SUM(oi.price + oi.freight_value)                    AS total_gmv
    FROM olist_order_items oi
    JOIN olist_orders o      ON oi.order_id = o.order_id
    LEFT JOIN olist_order_reviews r ON o.order_id = r.order_id
    GROUP BY oi.seller_id
)

SELECT
    seller_id,
    total_orders,
    canceled_orders,
    ROUND(canceled_orders * 100.0 / total_orders, 1)   AS cancel_rate_pct,
    ROUND(avg_review_score, 2)                          AS avg_review_score,
    ROUND(total_gmv, 2)                                 AS total_gmv,
    CASE
        WHEN canceled_orders * 100.0 / total_orders > 30
             AND total_orders >= 5                      THEN 'Escalate'
        WHEN avg_review_score < 3.0 
             AND total_orders >= 20                     THEN 'Quality Review'
        WHEN total_gmv > 10000 
             AND avg_review_score < 3.5                 THEN 'Priority Support'
        ELSE                                                'Healthy'
    END AS seller_status
FROM seller_order_stats
ORDER BY cancel_rate_pct DESC;
