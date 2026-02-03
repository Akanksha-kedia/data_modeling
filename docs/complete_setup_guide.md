# Complete Setup Guide - Data Modeling Demo

## 🎯 **Quick Start**
This guide provides step-by-step instructions to set up and run the complete data modeling demo with Apache Pinot.

## 📦 **What's Included**
```
data-modeling-demo/
├── README.md                           # Project overview
├── sql/
│   ├── 01_create_dimension_tables.sql  # Dimension table schemas
│   ├── 02_create_fact_table.sql        # Fact table schema  
│   └── 03_analytical_queries.sql       # Sample business queries
├── data/
│   ├── sample_customers.csv            # Customer dimension data
│   ├── sample_products.csv             # Product dimension data
│   └── sample_fact_sales.csv           # Sales fact data
├── configs/
│   └── pinot_fact_table_config.json    # Pinot table configuration
└── docs/
    ├── pinot_implementation_guide.md   # Detailed Pinot setup
    └── complete_setup_guide.md         # This file
```

## 🏗️ **Data Model Architecture**

### Star Schema Design
```
         dim_time (Calendar)
               │
               ▼
dim_customers ──┤ fact_sales_transactions ├── dim_products
               ▲                          
               │                          
         dim_stores (Locations)           
```

### Key Components

#### **Fact Table** - `fact_sales_transactions`
- **Primary Purpose**: Store business events (orders, sales, returns)  
- **Granularity**: One row per order line item
- **Key Measures**: Revenue, profit, quantities, costs
- **Row Volume**: High (millions+ rows expected)

#### **Dimension Tables**
- **dim_customers**: Customer master with SCD Type 2
- **dim_products**: Product catalog with 3-level hierarchy  
- **dim_stores**: Store/location information
- **dim_time**: Calendar dimension for time analysis

## 🚀 **Setup Instructions**

### Prerequisites
```bash
# Install required software
- PostgreSQL or MySQL (for traditional SQL examples)
- Apache Pinot (for real-time analytics)
- Apache Kafka (optional - for streaming)
- Python 3.8+ (for data generation scripts)
```

### Step 1: Traditional Database Setup

#### Create Tables
```bash
# Connect to your database
psql -U username -d database_name

# Execute schema creation scripts
\i sql/01_create_dimension_tables.sql
\i sql/02_create_fact_table.sql
```

#### Load Sample Data
```sql
-- Load dimension data
COPY dim_customers FROM 'data/sample_customers.csv' 
WITH (FORMAT csv, HEADER true);

COPY dim_products FROM 'data/sample_products.csv' 
WITH (FORMAT csv, HEADER true);

-- Load fact data  
COPY fact_sales_transactions FROM 'data/sample_fact_sales.csv'
WITH (FORMAT csv, HEADER true);
```

#### Test with Sample Queries
```bash
# Run analytical queries
\i sql/03_analytical_queries.sql
```

### Step 2: Apache Pinot Setup

#### Start Pinot Cluster
```bash
# Download and start Pinot (Quick Start)
wget https://archive.apache.org/dist/pinot/apache-pinot-0.12.0/apache-pinot-0.12.0-bin.tar.gz
tar -xzf apache-pinot-0.12.0-bin.tar.gz
cd apache-pinot-0.12.0-bin

# Start cluster components
bin/pinot-admin.sh QuickStart -type batch
```

#### Create Pinot Table
```bash
# Create table using configuration
bin/pinot-admin.sh AddTable \
  -tableConfigFile ../data-modeling-demo/configs/pinot_fact_table_config.json \
  -exec
```

#### Ingest Data
```bash
# Create ingestion job
bin/pinot-admin.sh LaunchDataIngestionJob \
  -jobSpecFile ingestion_job_spec.yaml
```

### Step 3: Verify Setup

#### Check Data Loading
```sql
-- Connect to Pinot and verify data
SELECT COUNT(*) FROM fact_sales_transactions;

-- Test analytical query
SELECT 
    transaction_type,
    COUNT(*) as transaction_count,
    SUM(net_sales_amount) as total_revenue
FROM fact_sales_transactions 
GROUP BY transaction_type;
```

## 🔍 **Key Learning Concepts**

### 1. **Fact vs Dimension Tables**
```sql
-- Fact Table Characteristics
- Contains business measures (revenue, quantities, costs)
- High volume, frequently inserted
- Foreign keys to dimension tables
- Optimized for analytical queries

-- Dimension Table Characteristics  
- Contains descriptive attributes (names, categories, locations)
- Lower volume, slowly changing
- Provides context for fact data
- Support for hierarchies (product categories, geographic regions)
```

### 2. **Types of Keys Used**

#### **Surrogate Keys**
- Artificial primary keys (customer_sk, product_sk)
- Benefits: Performance, SCD support, data integration

#### **Natural Keys** 
- Business identifiers (customer_id, product_id, order_id)
- Benefits: Business meaning, data quality validation

#### **Foreign Keys**
- Links between fact and dimension tables
- Enable join operations for analysis

### 3. **Schema Types Demonstrated**

#### **Star Schema**
```
- Central fact table surrounded by dimension tables
- Denormalized design for optimal query performance  
- Suitable for OLAP and business intelligence
```

#### **Slowly Changing Dimensions (SCD)**
```sql
-- Type 2 SCD example in dim_customers
effective_start_date DATE NOT NULL,
effective_end_date DATE NOT NULL, 
is_current BOOLEAN NOT NULL
```

### 4. **Measure Types**

#### **Additive Measures**
```sql
SUM(net_sales_amount)    -- Can be summed across all dimensions
SUM(quantity_ordered)    -- Meaningful totals across time/geography
```

#### **Semi-Additive Measures**  
```sql
AVG(inventory_quantity)  -- Averages across time, sums across other dims
```

#### **Non-Additive Measures**
```sql
AVG(profit_margin_percentage)  -- Ratios require special handling
```

## 📊 **Business Use Cases**

### Real-time Dashboards
- **Sales Performance**: Revenue, orders, growth trends
- **Customer Analytics**: Segmentation, behavior, lifetime value  
- **Product Analysis**: Top sellers, inventory levels, profitability
- **Geographic Insights**: Regional performance, store comparisons

### Analytical Reports
- **Monthly Business Reviews**: KPI trending and variance analysis
- **Product Category Performance**: Hierarchy-based analysis
- **Customer Segmentation**: RFM analysis and cohort studies  
- **Seasonal Analysis**: Holiday patterns and demand forecasting

## 🔧 **Advanced Features**

### Performance Optimization
```sql
-- Partitioning strategy
PARTITION BY order_date_sk;

-- Indexing for fast lookups  
CREATE INDEX idx_customer_segment ON dim_customers(customer_segment);
CREATE INDEX idx_order_date ON fact_sales_transactions(order_date_sk);
```

### Data Quality
```sql
-- Validation queries
SELECT COUNT(*) FROM fact_sales_transactions 
WHERE customer_sk NOT IN (SELECT customer_sk FROM dim_customers);

-- Data freshness check
SELECT MAX(order_timestamp) as latest_order FROM fact_sales_transactions;
```

## 🎓 **Next Steps**

1. **Extend the Model**: Add more dimensions (promotions, channels, territories)
2. **Real-time Streaming**: Implement Kafka-based data ingestion  
3. **Advanced Analytics**: Add calculated measures, time intelligence
4. **Visualization**: Connect Tableau, Grafana, or other BI tools
5. **Machine Learning**: Use the data for predictive modeling

## 📚 **Additional Resources**

- **Star Schema Design**: Kimball dimensional modeling methodology
- **Apache Pinot Documentation**: https://docs.pinot.apache.org/  
- **Data Warehouse Toolkit**: Ralph Kimball's design patterns
- **OLAP Best Practices**: Query optimization and performance tuning

This setup provides a solid foundation for learning data modeling concepts while demonstrating practical implementation with both traditional databases and modern real-time analytical systems like Apache Pinot.
