# Apache Pinot Implementation Guide

## 🎯 **Overview**
This guide demonstrates how to implement the e-commerce data model using Apache Pinot, a real-time analytical database optimized for OLAP queries.

## 📋 **Prerequisites**
- Apache Pinot cluster (v0.12.0+)
- Apache Kafka (for real-time data ingestion)
- Sample data files (provided in `/data` directory)

## 🚀 **Implementation Steps**

### Step 1: Create Pinot Tables

#### Option A: Using Pinot Admin Console UI
1. Access Pinot Admin Console: `http://localhost:9000`
2. Navigate to "Tables" → "Add Table"
3. Upload table configuration JSON files from `/configs` directory

#### Option B: Using Pinot CLI
```bash
# Start Pinot Cluster (if not already running)
bin/pinot-admin.sh StartZookeeper
bin/pinot-admin.sh StartController
bin/pinot-admin.sh StartBroker  
bin/pinot-admin.sh StartServer

# Create tables using configuration files
bin/pinot-admin.sh AddTable \
  -tableConfigFile /path/to/pinot_fact_table_config.json \
  -exec
```

### Step 2: Data Ingestion

#### Batch Data Ingestion (CSV Files)
```bash
# Create ingestion job spec
cat > ingestion_job_spec.yaml << EOF
executionFrameworkSpec:
  name: 'standalone'
  segmentGenerationJobRunnerClassName: 'org.apache.pinot.plugin.ingestion.batch.standalone.SegmentGenerationJobRunner'
  segmentTarPushJobRunnerClassName: 'org.apache.pinot.plugin.ingestion.batch.standalone.SegmentTarPushJobRunner'

jobType: SegmentCreationAndTarPush
inputDirURI: '/path/to/data'
includeFileNamePattern: 'sample_fact_sales.csv'
outputDirURI: '/tmp/pinot-batch-ingestion/output'
overwriteOutput: true

pinotFSSpecs:
  - scheme: file
    className: org.apache.pinot.spi.filesystem.LocalPinotFS

recordReaderSpec:
  dataFormat: 'csv'
  className: 'org.apache.pinot.plugin.inputformat.csv.CSVRecordReader'
  configClassName: 'org.apache.pinot.plugin.inputformat.csv.CSVRecordReaderConfig'

tableSpec:
  tableName: 'fact_sales_transactions'

pinotClusterSpecs:
  - controllerURI: 'http://localhost:9000'
EOF

# Execute ingestion job
bin/pinot-admin.sh LaunchDataIngestionJob \
  -jobSpecFile ingestion_job_spec.yaml
```

#### Real-time Data Ingestion (Kafka)
```bash
# Create Kafka topic
kafka-topics.sh --create \
  --topic sales_transactions \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

# Configure real-time table (add to table config)
"streamConfigs": {
  "streamType": "kafka",
  "stream.kafka.consumer.type": "lowLevel",
  "stream.kafka.topic.name": "sales_transactions",
  "stream.kafka.decoder.class.name": "org.apache.pinot.plugin.stream.kafka.KafkaJSONMessageDecoder",
  "stream.kafka.consumer.factory.class.name": "org.apache.pinot.plugin.stream.kafka20.KafkaConsumerFactory",
  "stream.kafka.broker.list": "localhost:9092",
  "realtime.segment.flush.threshold.rows": "50000",
  "realtime.segment.flush.threshold.time": "3600000"
}
```

## 📊 **Pinot-Optimized Queries**

### 1. Real-time Sales Dashboard
```sql
-- Last 24 hours sales performance
SELECT 
  toDateTime(order_timestamp, 'yyyy-MM-dd HH:mm:ss') as order_time,
  SUM(net_sales_amount) as revenue,
  COUNT(*) as transaction_count
FROM fact_sales_transactions 
WHERE order_timestamp >= ago('PT24H')
  AND transaction_type = 'Sale'
GROUP BY toDateTime(order_timestamp, 'yyyy-MM-dd HH:mm:ss')
ORDER BY order_time DESC
LIMIT 100;
```

### 2. Top Products (Last Hour)
```sql
-- Hot products in real-time
SELECT 
  product_sk,
  SUM(quantity_ordered) as units_sold,
  SUM(net_sales_amount) as revenue,
  COUNT(DISTINCT customer_sk) as unique_buyers
FROM fact_sales_transactions 
WHERE order_timestamp >= ago('PT1H')
  AND transaction_type = 'Sale'
GROUP BY product_sk
ORDER BY revenue DESC
LIMIT 10;
```

### 3. Geographic Heatmap Data
```sql
-- Sales by region for real-time mapping
SELECT 
  store_sk,
  COUNT(*) as transaction_count,
  SUM(net_sales_amount) as total_revenue,
  AVG(net_sales_amount) as avg_order_value
FROM fact_sales_transactions 
WHERE order_timestamp >= ago('PT6H')
  AND transaction_type = 'Sale'
GROUP BY store_sk
ORDER BY total_revenue DESC;
```

## ⚡ **Performance Optimization**

### Indexing Strategy
```json
{
  "tableIndexConfig": {
    "invertedIndexColumns": [
      "customer_sk", "product_sk", "store_sk", 
      "transaction_type", "payment_method"
    ],
    "bloomFilterColumns": [
      "order_id", "promotion_code"
    ],
    "rangeIndexColumns": [
      "order_timestamp", "net_sales_amount", "quantity_ordered"
    ],
    "sortedColumn": ["order_timestamp"]
  }
}
```

### Partitioning Strategy
```json
{
  "segmentsConfig": {
    "timeType": "DAYS",
    "timeColumnName": "order_timestamp",
    "segmentPushType": "APPEND",
    "replication": "2"
  }
}
```

### Star-Tree Index (Advanced)
```json
{
  "starTreeIndexConfigs": [
    {
      "dimensionsSplitOrder": [
        "customer_sk", "product_sk", "store_sk", "order_date_sk"
      ],
      "skipStarNodeCreationForDimensions": [],
      "functionColumnPairs": [
        "SUM__net_sales_amount",
        "COUNT__transaction_sk",
        "MAX__order_timestamp"
      ],
      "maxLeafRecords": 1000
    }
  ]
}
```

## 🔧 **Monitoring & Maintenance**

### Health Checks
```bash
# Check cluster status
curl "http://localhost:9000/health"

# Check table stats
curl "http://localhost:9000/tables/fact_sales_transactions/size"

# Query performance metrics
curl "http://localhost:9000/debug/tables/fact_sales_transactions/querystats"
```

### Common Maintenance Tasks
```sql
-- Reload table metadata
RELOAD TABLE fact_sales_transactions;

-- Reset segments
RESET SEGMENT fact_sales_transactions_OFFLINE_20240101_20240131_0;

-- Get table configuration
SHOW TABLE fact_sales_transactions;
```

## 🎛️ **Integration Examples**

### Python Client
```python
from pinotdb import connect

# Connect to Pinot
conn = connect(host='localhost', port=8000, path='/query/sql', scheme='http')
cursor = conn.cursor()

# Execute query
cursor.execute("""
  SELECT customer_segment, SUM(net_sales_amount) as revenue
  FROM fact_sales_transactions 
  WHERE order_timestamp >= ago('PT24H')
  GROUP BY customer_segment
  ORDER BY revenue DESC
""")

results = cursor.fetchall()
print(results)
```

### REST API
```bash
# Query via REST API
curl -X POST \
  'http://localhost:8000/query/sql' \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT COUNT(*) FROM fact_sales_transactions WHERE transaction_type = '\''Sale'\''"
  }'
```

## 📈 **Business Intelligence Integration**

### Grafana Dashboard
- Configure Pinot as data source: `http://localhost:8000/query/sql`
- Create panels for KPIs: revenue, orders, customers
- Set up alerts for anomaly detection

### Tableau Connection
1. Install Pinot JDBC driver
2. Connection URL: `jdbc:pinot://localhost:8000/query/sql`
3. Create extracts for dimension tables
4. Build interactive dashboards

## 🚨 **Troubleshooting**

### Common Issues
1. **Slow Queries**: Add appropriate indexes, check filter selectivity
2. **High Memory Usage**: Tune JVM settings, optimize star-tree indexes
3. **Ingestion Failures**: Check data format, validate timestamps
4. **Missing Data**: Verify Kafka connectivity, check consumer lag

### Debug Commands
```bash
# Check segment status
curl "http://localhost:9000/debug/tables/fact_sales_transactions/segments"

# Validate table config
bin/pinot-admin.sh ValidateConfig -tableConfigFile config.json

# Check query execution plan
curl -X POST 'http://localhost:8000/query/sql' -d '{"sql":"EXPLAIN PLAN FOR SELECT..."}'
```

## 🎯 **Best Practices**

1. **Time-based Partitioning**: Always partition by timestamp
2. **Selective Indexing**: Index frequently filtered columns
3. **Proper Data Types**: Use appropriate types for better compression
4. **Monitoring**: Set up alerts for performance metrics
5. **Testing**: Validate queries with production-like data volumes

This implementation provides a solid foundation for real-time analytics with Apache Pinot, enabling fast OLAP queries on your e-commerce data model.
