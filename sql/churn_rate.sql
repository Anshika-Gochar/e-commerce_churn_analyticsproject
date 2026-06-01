
-- ================================================
-- CHURN RATE CALCULATION
-- Churn defined as no purchase in 180+ days
-- ================================================

WITH last_orders AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_order_date
    FROM olist_orders o
    JOIN olist_customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

churn_flags AS (
    SELECT
        customer_unique_id,
        last_order_date,
        JULIANDAY('2018-10-17') - JULIANDAY(last_order_date) AS days_since_order,
        CASE
            WHEN JULIANDAY('2018-10-17') - 
                 JULIANDAY(last_order_date) > 180 THEN 1
            ELSE 0
        END AS is_churned
    FROM last_orders
)

SELECT
    COUNT(*)                                           AS total_customers,
    SUM(is_churned)                                    AS churned_customers,
    COUNT(*) - SUM(is_churned)                         AS active_customers,
    ROUND(SUM(is_churned) * 100.0 / COUNT(*), 1)      AS churn_rate_pct,
    ROUND(AVG(days_since_order), 0)                    AS avg_days_since_order
FROM churn_flags;
