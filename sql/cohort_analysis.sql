
-- ================================================
-- COHORT RETENTION ANALYSIS
-- Tracks what % of customers return each month
-- ================================================

WITH first_orders AS (
    SELECT
        c.customer_unique_id,
        DATE(MIN(o.order_purchase_timestamp), 'start of month') AS cohort_month
    FROM olist_orders o
    JOIN olist_customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

order_months AS (
    SELECT
        c.customer_unique_id,
        DATE(o.order_purchase_timestamp, 'start of month') AS order_month
    FROM olist_orders o
    JOIN olist_customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),

cohort_data AS (
    SELECT
        f.cohort_month,
        CAST(
            (JULIANDAY(om.order_month) - JULIANDAY(f.cohort_month)) / 30
        AS INTEGER)                                        AS cohort_index,
        COUNT(DISTINCT om.customer_unique_id)              AS active_customers
    FROM first_orders f
    JOIN order_months om ON f.customer_unique_id = om.customer_unique_id
    GROUP BY f.cohort_month, cohort_index
),

cohort_sizes AS (
    SELECT cohort_month, active_customers AS cohort_size
    FROM cohort_data
    WHERE cohort_index = 0
)

SELECT
    cd.cohort_month,
    cd.cohort_index,
    cd.active_customers,
    cs.cohort_size,
    ROUND(cd.active_customers * 100.0 / cs.cohort_size, 1) AS retention_pct
FROM cohort_data cd
JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
ORDER BY cd.cohort_month, cd.cohort_index;
