-- =====================================================
-- DIMENSION TABLES CREATION SCRIPTS
-- Data Modeling Demo - E-commerce Schema
-- =====================================================

-- 1. CUSTOMER DIMENSION TABLE
-- Contains customer master data with SCD Type 2 support
-- =====================================================
CREATE TABLE dim_customers (
    customer_sk BIGINT NOT NULL,                    -- Surrogate Key
    customer_id VARCHAR(50) NOT NULL,               -- Business Key
    customer_name VARCHAR(200) NOT NULL,
    email VARCHAR(200),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10),
    customer_segment VARCHAR(50),                   -- Premium, Standard, Basic
    customer_status VARCHAR(20),                    -- Active, Inactive, Suspended
    registration_date DATE,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    
    -- SCD Type 2 Fields
    effective_start_date DATE NOT NULL,
    effective_end_date DATE NOT NULL,
    is_current BOOLEAN NOT NULL,
    created_timestamp TIMESTAMP,
    updated_timestamp TIMESTAMP,
    
    PRIMARY KEY (customer_sk)
);

-- 2. PRODUCT DIMENSION TABLE  
-- Contains product catalog with hierarchies
-- =====================================================
CREATE TABLE dim_products (
    product_sk BIGINT NOT NULL,                     -- Surrogate Key
    product_id VARCHAR(50) NOT NULL,                -- Business Key (SKU)
    product_name VARCHAR(200) NOT NULL,
    product_description TEXT,
    
    -- Product Hierarchy
    category_level_1 VARCHAR(100),                  -- Electronics, Clothing, Books
    category_level_2 VARCHAR(100),                  -- Smartphones, Laptops, Fiction
    category_level_3 VARCHAR(100),                  -- iPhone, Gaming Laptops, Sci-Fi
    
    brand VARCHAR(100),
    manufacturer VARCHAR(100),
    product_color VARCHAR(50),
    product_size VARCHAR(50),
    product_weight DECIMAL(10,2),
    
    -- Pricing Information
    standard_cost DECIMAL(15,2),
    list_price DECIMAL(15,2),
    
    -- Product Status
    product_status VARCHAR(20),                     -- Active, Discontinued, Seasonal
    launch_date DATE,
    
    -- Audit Fields
    created_timestamp TIMESTAMP,
    updated_timestamp TIMESTAMP,
    
    PRIMARY KEY (product_sk)
);

-- 3. STORE DIMENSION TABLE
-- Contains store/location information
-- =====================================================
CREATE TABLE dim_stores (
    store_sk BIGINT NOT NULL,                       -- Surrogate Key
    store_id VARCHAR(50) NOT NULL,                  -- Business Key
    store_name VARCHAR(200) NOT NULL,
    store_type VARCHAR(50),                         -- Physical, Online, Hybrid
    
    -- Geographic Hierarchy
    store_address VARCHAR(500),
    city VARCHAR(100),
    state VARCHAR(100), 
    country VARCHAR(100),
    postal_code VARCHAR(20),
    region VARCHAR(100),                            -- North, South, East, West
    district VARCHAR(100),
    
    -- Store Details
    store_size_sqft INT,
    opening_date DATE,
    store_manager VARCHAR(200),
    phone VARCHAR(20),
    email VARCHAR(200),
    
    -- Operational Status
    store_status VARCHAR(20),                       -- Open, Closed, Under Renovation
    
    -- Audit Fields
    created_timestamp TIMESTAMP,
    updated_timestamp TIMESTAMP,
    
    PRIMARY KEY (store_sk)
);

-- 4. TIME DIMENSION TABLE
-- Contains calendar hierarchy for time-based analysis
-- =====================================================
CREATE TABLE dim_time (
    time_sk BIGINT NOT NULL,                        -- Surrogate Key (YYYYMMDD format)
    full_date DATE NOT NULL,                        -- Business Key
    
    -- Date Components
    day_of_month INT,
    day_of_week INT,                                -- 1=Monday, 7=Sunday
    day_of_year INT,
    day_name VARCHAR(20),                           -- Monday, Tuesday, etc.
    day_name_short VARCHAR(10),                     -- Mon, Tue, etc.
    
    -- Week Information
    week_of_month INT,
    week_of_year INT,
    week_start_date DATE,
    week_end_date DATE,
    
    -- Month Information
    month_number INT,
    month_name VARCHAR(20),                         -- January, February, etc.
    month_name_short VARCHAR(10),                   -- Jan, Feb, etc.
    month_start_date DATE,
    month_end_date DATE,
    
    -- Quarter Information
    quarter_number INT,
    quarter_name VARCHAR(10),                       -- Q1, Q2, Q3, Q4
    quarter_start_date DATE,
    quarter_end_date DATE,
    
    -- Year Information
    year_number INT,
    
    -- Business Flags
    is_weekend BOOLEAN,
    is_holiday BOOLEAN,
    holiday_name VARCHAR(200),
    is_business_day BOOLEAN,
    
    -- Fiscal Calendar (if different from calendar year)
    fiscal_month INT,
    fiscal_quarter INT,
    fiscal_year INT,
    
    PRIMARY KEY (time_sk)
);

-- Create indexes for better query performance
CREATE INDEX idx_dim_customers_customer_id ON dim_customers(customer_id);
CREATE INDEX idx_dim_customers_segment ON dim_customers(customer_segment);
CREATE INDEX idx_dim_customers_current ON dim_customers(is_current);

CREATE INDEX idx_dim_products_product_id ON dim_products(product_id);
CREATE INDEX idx_dim_products_category_l1 ON dim_products(category_level_1);
CREATE INDEX idx_dim_products_brand ON dim_products(brand);

CREATE INDEX idx_dim_stores_store_id ON dim_stores(store_id);
CREATE INDEX idx_dim_stores_region ON dim_stores(region);
CREATE INDEX idx_dim_stores_country ON dim_stores(country);

CREATE INDEX idx_dim_time_date ON dim_time(full_date);
CREATE INDEX idx_dim_time_month ON dim_time(month_number, year_number);
CREATE INDEX idx_dim_time_quarter ON dim_time(quarter_number, year_number);
