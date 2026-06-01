
-- ================================================
-- RFM SEGMENTATION QUERY
-- Dataset: Olist E-commerce (olist_orders + olist_customers)
-- Author: [Your Name]
-- ================================================

WITH delivered_orders AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        oi.price + oi.freight_value AS order_value
    FROM olist_orders o
    JOIN olist_customers c ON o.customer_id = c.customer_id
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),

rfm_raw AS (
    SELECT
        customer_unique_id,
        MAX(order_purchase_timestamp)                          AS last_order_date,
        COUNT(DISTINCT order_id)                               AS frequency,
        SUM(order_value)                                       AS monetary,
        JULIANDAY('2018-10-17') - 
            JULIANDAY(MAX(order_purchase_timestamp))           AS recency_days
    FROM delivered_orders
    GROUP BY customer_unique_id
),

rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score
    FROM rfm_raw
)

SELECT
    customer_unique_id,
    recency_days,
    frequency,
    ROUND(monetary, 2)          AS monetary,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4              THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3              THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2              THEN 'Recent Customers'
        WHEN r_score >= 3 AND m_score >= 3              THEN 'Potential Loyalists'
        WHEN r_score = 2  AND f_score >= 2              THEN 'At-Risk'
        WHEN r_score <= 2 AND f_score >= 3              THEN 'Can''t Lose Them'
        WHEN r_score = 2  AND f_score = 1               THEN 'Hibernating'
        ELSE                                                 'Lost'
    END AS segment
FROM rfm_scored
ORDER BY monetary DESC;
