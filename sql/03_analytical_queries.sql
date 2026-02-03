-- =====================================================
-- ANALYTICAL QUERIES - DATA MODELING DEMO
-- Sample business intelligence queries for e-commerce
-- =====================================================

-- 1. MONTHLY SALES PERFORMANCE ANALYSIS
-- Shows sales trends by month with year-over-year comparison
-- =====================================================
SELECT 
    dt.month_name,
    dt.year_number,
    COUNT(DISTINCT f.order_id) as total_orders,
    SUM(f.quantity_ordered) as total_items_sold,
    SUM(f.net_sales_amount) as total_revenue,
    AVG(f.net_sales_amount) as avg_order_value,
    SUM(f.gross_profit) as total_profit,
    ROUND(SUM(f.gross_profit) / SUM(f.net_sales_amount) * 100, 2) as profit_margin_pct
FROM fact_sales_transactions f
JOIN dim_time dt ON f.order_date_sk = dt.time_sk
WHERE dt.year_number IN (2024, 2023)
    AND f.transaction_type = 'Sale'
GROUP BY dt.month_name, dt.year_number
ORDER BY dt.year_number, dt.month_number;

-- 2. CUSTOMER SEGMENTATION ANALYSIS  
-- Revenue and behavior analysis by customer segment
-- =====================================================
SELECT 
    c.customer_segment,
    COUNT(DISTINCT c.customer_sk) as total_customers,
    COUNT(DISTINCT f.order_id) as total_orders,
    SUM(f.net_sales_amount) as total_revenue,
    AVG(f.net_sales_amount) as avg_order_value,
    SUM(f.net_sales_amount) / COUNT(DISTINCT c.customer_sk) as revenue_per_customer,
    COUNT(DISTINCT f.order_id) / COUNT(DISTINCT c.customer_sk) as orders_per_customer
FROM fact_sales_transactions f
JOIN dim_customers c ON f.customer_sk = c.customer_sk
WHERE f.transaction_type = 'Sale'
    AND c.is_current = TRUE
GROUP BY c.customer_segment
ORDER BY total_revenue DESC;

-- 3. PRODUCT CATEGORY PERFORMANCE
-- Sales performance by product hierarchy levels
-- =====================================================
SELECT 
    p.category_level_1,
    p.category_level_2,
    p.brand,
    COUNT(DISTINCT f.order_id) as orders,
    SUM(f.quantity_ordered) as units_sold,
    SUM(f.net_sales_amount) as revenue,
    SUM(f.gross_profit) as profit,
    AVG(f.unit_price) as avg_selling_price,
    ROUND(SUM(f.gross_profit) / SUM(f.net_sales_amount) * 100, 2) as profit_margin_pct
FROM fact_sales_transactions f
JOIN dim_products p ON f.product_sk = p.product_sk
WHERE f.transaction_type = 'Sale'
GROUP BY p.category_level_1, p.category_level_2, p.brand
HAVING SUM(f.net_sales_amount) > 1000
ORDER BY revenue DESC;

-- 4. GEOGRAPHIC SALES ANALYSIS
-- Revenue distribution by store location and region
-- =====================================================
SELECT 
    s.region,
    s.state,
    s.city,
    COUNT(DISTINCT f.order_id) as total_orders,
    SUM(f.net_sales_amount) as total_revenue,
    AVG(f.net_sales_amount) as avg_order_value,
    COUNT(DISTINCT f.customer_sk) as unique_customers
FROM fact_sales_transactions f
JOIN dim_stores s ON f.store_sk = s.store_sk
WHERE f.transaction_type = 'Sale'
GROUP BY s.region, s.state, s.city
ORDER BY total_revenue DESC;

-- 5. SEASONAL TRENDS ANALYSIS
-- Quarterly and seasonal performance patterns
-- =====================================================
SELECT 
    dt.quarter_name,
    dt.year_number,
    p.category_level_1,
    COUNT(*) as transaction_count,
    SUM(f.net_sales_amount) as revenue,
    AVG(f.net_sales_amount) as avg_transaction_value,
    SUM(f.quantity_ordered) as total_units
FROM fact_sales_transactions f
JOIN dim_time dt ON f.order_date_sk = dt.time_sk
JOIN dim_products p ON f.product_sk = p.product_sk
WHERE f.transaction_type = 'Sale'
GROUP BY dt.quarter_name, dt.year_number, p.category_level_1
ORDER BY dt.year_number, dt.quarter_number, revenue DESC;

-- 6. CUSTOMER PURCHASE BEHAVIOR
-- Analysis of customer buying patterns and preferences
-- =====================================================
WITH customer_metrics AS (
    SELECT 
        c.customer_sk,
        c.customer_name,
        c.customer_segment,
        c.city,
        c.state,
        COUNT(DISTINCT f.order_id) as total_orders,
        SUM(f.net_sales_amount) as total_spent,
        AVG(f.net_sales_amount) as avg_order_value,
        MIN(f.order_timestamp) as first_purchase,
        MAX(f.order_timestamp) as last_purchase,
        COUNT(DISTINCT p.category_level_1) as category_diversity
    FROM dim_customers c
    JOIN fact_sales_transactions f ON c.customer_sk = f.customer_sk
    JOIN dim_products p ON f.product_sk = p.product_sk
    WHERE f.transaction_type = 'Sale'
        AND c.is_current = TRUE
    GROUP BY c.customer_sk, c.customer_name, c.customer_segment, c.city, c.state
)
SELECT 
    customer_segment,
    AVG(total_orders) as avg_orders_per_customer,
    AVG(total_spent) as avg_spending_per_customer,
    AVG(avg_order_value) as avg_order_size,
    AVG(category_diversity) as avg_categories_purchased,
    COUNT(*) as customers_in_segment
FROM customer_metrics
GROUP BY customer_segment
ORDER BY avg_spending_per_customer DESC;

-- 7. PAYMENT METHOD ANALYSIS
-- Performance analysis by payment method
-- =====================================================
SELECT 
    f.payment_method,
    COUNT(*) as transaction_count,
    SUM(f.net_sales_amount) as total_revenue,
    AVG(f.net_sales_amount) as avg_transaction_value,
    SUM(f.quantity_ordered) as total_items,
    COUNT(DISTINCT f.customer_sk) as unique_customers,
    ROUND(SUM(f.net_sales_amount) / COUNT(*), 2) as revenue_per_transaction
FROM fact_sales_transactions f
WHERE f.transaction_type = 'Sale'
GROUP BY f.payment_method
ORDER BY total_revenue DESC;

-- 8. RETURN ANALYSIS
-- Analysis of product returns and their impact
-- =====================================================
SELECT 
    p.category_level_1,
    p.brand,
    COUNT(CASE WHEN f.transaction_type = 'Sale' THEN 1 END) as sales_count,
    COUNT(CASE WHEN f.transaction_type = 'Return' THEN 1 END) as return_count,
    ROUND(
        COUNT(CASE WHEN f.transaction_type = 'Return' THEN 1 END) * 100.0 / 
        COUNT(CASE WHEN f.transaction_type = 'Sale' THEN 1 END), 2
    ) as return_rate_pct,
    SUM(CASE WHEN f.transaction_type = 'Sale' THEN f.net_sales_amount ELSE 0 END) as sales_revenue,
    ABS(SUM(CASE WHEN f.transaction_type = 'Return' THEN f.net_sales_amount ELSE 0 END)) as return_amount
FROM fact_sales_transactions f
JOIN dim_products p ON f.product_sk = p.product_sk
GROUP BY p.category_level_1, p.brand
HAVING COUNT(CASE WHEN f.transaction_type = 'Sale' THEN 1 END) > 0
ORDER BY return_rate_pct DESC;

-- 9. TIME-BASED PERFORMANCE METRICS
-- Daily, weekly, and monthly KPIs for business monitoring
-- =====================================================
SELECT 
    dt.full_date,
    dt.day_name,
    dt.month_name,
    dt.is_weekend,
    COUNT(DISTINCT f.order_id) as daily_orders,
    SUM(f.net_sales_amount) as daily_revenue,
    SUM(f.quantity_ordered) as daily_units_sold,
    COUNT(DISTINCT f.customer_sk) as daily_active_customers,
    AVG(f.net_sales_amount) as avg_order_value
FROM fact_sales_transactions f
JOIN dim_time dt ON f.order_date_sk = dt.time_sk
WHERE f.transaction_type = 'Sale'
    AND dt.full_date >= '2024-01-01'
GROUP BY dt.full_date, dt.day_name, dt.month_name, dt.is_weekend
ORDER BY dt.full_date;

-- 10. PROMOTION EFFECTIVENESS ANALYSIS
-- Impact of promotional campaigns on sales
-- =====================================================
SELECT 
    CASE 
        WHEN f.promotion_code IS NULL OR f.promotion_code = '' THEN 'No Promotion'
        ELSE f.promotion_code
    END as promotion_status,
    COUNT(*) as transaction_count,
    SUM(f.gross_sales_amount) as gross_revenue,
    SUM(f.discount_amount) as total_discounts,
    SUM(f.net_sales_amount) as net_revenue,
    AVG(f.discount_percentage) as avg_discount_pct,
    SUM(f.gross_profit) as total_profit,
    ROUND(SUM(f.gross_profit) / SUM(f.net_sales_amount) * 100, 2) as profit_margin_pct
FROM fact_sales_transactions f
WHERE f.transaction_type = 'Sale'
GROUP BY 
    CASE 
        WHEN f.promotion_code IS NULL OR f.promotion_code = '' THEN 'No Promotion'
        ELSE f.promotion_code
    END
ORDER BY net_revenue DESC;
