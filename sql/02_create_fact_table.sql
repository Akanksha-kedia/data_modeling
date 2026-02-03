-- =====================================================
-- FACT TABLE CREATION SCRIPT
-- Data Modeling Demo - E-commerce Schema
-- =====================================================

-- SALES TRANSACTIONS FACT TABLE
-- Contains business events - orders, sales, revenue
-- High volume, frequently queried, optimized for analytics
-- =====================================================
CREATE TABLE fact_sales_transactions (
    
    -- Surrogate Primary Key
    transaction_sk BIGINT NOT NULL,
    
    -- Foreign Keys to Dimension Tables
    customer_sk BIGINT NOT NULL,                    -- Links to dim_customers
    product_sk BIGINT NOT NULL,                     -- Links to dim_products  
    store_sk BIGINT NOT NULL,                       -- Links to dim_stores
    order_date_sk BIGINT NOT NULL,                  -- Links to dim_time (order date)
    ship_date_sk BIGINT,                            -- Links to dim_time (ship date)
    
    -- Degenerate Dimensions (attributes stored in fact table)
    order_id VARCHAR(50) NOT NULL,                  -- Order identifier
    order_line_number INT NOT NULL,                 -- Line item number
    transaction_type VARCHAR(20),                   -- Sale, Return, Exchange
    payment_method VARCHAR(50),                     -- Credit Card, Cash, PayPal
    promotion_code VARCHAR(50),                     -- Discount code applied
    
    -- Additive Measures (can be summed across dimensions)
    quantity_ordered INT NOT NULL,
    quantity_shipped INT,
    quantity_returned INT,
    
    unit_price DECIMAL(15,2) NOT NULL,
    unit_cost DECIMAL(15,2),
    discount_amount DECIMAL(15,2),
    tax_amount DECIMAL(15,2),
    shipping_amount DECIMAL(15,2),
    
    -- Calculated Revenue Measures
    gross_sales_amount DECIMAL(15,2),               -- unit_price * quantity_ordered
    net_sales_amount DECIMAL(15,2),                 -- gross_sales - discount - returns
    total_cost DECIMAL(15,2),                       -- unit_cost * quantity_ordered
    gross_profit DECIMAL(15,2),                     -- net_sales - total_cost
    
    -- Semi-Additive Measures (inventory levels)
    inventory_quantity INT,
    
    -- Non-Additive Measures (ratios, percentages)
    discount_percentage DECIMAL(5,2),
    profit_margin_percentage DECIMAL(5,2),
    
    -- Business Process Timestamps
    order_timestamp TIMESTAMP NOT NULL,
    payment_timestamp TIMESTAMP,
    ship_timestamp TIMESTAMP,
    delivery_timestamp TIMESTAMP,
    
    -- Row-level Metadata
    source_system VARCHAR(50),
    created_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Data Quality Indicators
    data_quality_score DECIMAL(3,2),               -- 0.00 to 1.00
    is_processed BOOLEAN DEFAULT FALSE,
    
    PRIMARY KEY (transaction_sk)
);

-- =====================================================
-- FOREIGN KEY CONSTRAINTS
-- =====================================================
ALTER TABLE fact_sales_transactions 
ADD CONSTRAINT fk_customer 
FOREIGN KEY (customer_sk) REFERENCES dim_customers(customer_sk);

ALTER TABLE fact_sales_transactions 
ADD CONSTRAINT fk_product 
FOREIGN KEY (product_sk) REFERENCES dim_products(product_sk);

ALTER TABLE fact_sales_transactions 
ADD CONSTRAINT fk_store 
FOREIGN KEY (store_sk) REFERENCES dim_stores(store_sk);

ALTER TABLE fact_sales_transactions 
ADD CONSTRAINT fk_order_date 
FOREIGN KEY (order_date_sk) REFERENCES dim_time(time_sk);

ALTER TABLE fact_sales_transactions 
ADD CONSTRAINT fk_ship_date 
FOREIGN KEY (ship_date_sk) REFERENCES dim_time(time_sk);

-- =====================================================
-- PERFORMANCE OPTIMIZATION INDEXES
-- =====================================================

-- Primary access patterns
CREATE INDEX idx_fact_sales_order_date ON fact_sales_transactions(order_date_sk);
CREATE INDEX idx_fact_sales_customer ON fact_sales_transactions(customer_sk);
CREATE INDEX idx_fact_sales_product ON fact_sales_transactions(product_sk);
CREATE INDEX idx_fact_sales_store ON fact_sales_transactions(store_sk);

-- Business process indexes
CREATE INDEX idx_fact_sales_order_id ON fact_sales_transactions(order_id);
CREATE INDEX idx_fact_sales_transaction_type ON fact_sales_transactions(transaction_type);

-- Time-based partitioning support
CREATE INDEX idx_fact_sales_order_timestamp ON fact_sales_transactions(order_timestamp);

-- Composite indexes for common query patterns
CREATE INDEX idx_fact_sales_customer_date ON fact_sales_transactions(customer_sk, order_date_sk);
CREATE INDEX idx_fact_sales_product_store ON fact_sales_transactions(product_sk, store_sk);
CREATE INDEX idx_fact_sales_date_store ON fact_sales_transactions(order_date_sk, store_sk);

-- Revenue analysis index
CREATE INDEX idx_fact_sales_net_sales ON fact_sales_transactions(net_sales_amount) 
WHERE net_sales_amount > 0;

-- =====================================================
-- TABLE COMMENTS FOR DOCUMENTATION
-- =====================================================
COMMENT ON TABLE fact_sales_transactions IS 
'Sales transactions fact table containing order line items with associated measures and foreign keys to dimension tables. Optimized for OLAP queries and business intelligence reporting.';

COMMENT ON COLUMN fact_sales_transactions.transaction_sk IS 'Surrogate primary key for the fact table';
COMMENT ON COLUMN fact_sales_transactions.gross_sales_amount IS 'Total sales amount before discounts (unit_price * quantity_ordered)';
COMMENT ON COLUMN fact_sales_transactions.net_sales_amount IS 'Sales amount after discounts and returns';
COMMENT ON COLUMN fact_sales_transactions.gross_profit IS 'Profit calculated as net_sales - total_cost';
COMMENT ON COLUMN fact_sales_transactions.data_quality_score IS 'Data quality indicator from 0.00 (poor) to 1.00 (excellent)';
