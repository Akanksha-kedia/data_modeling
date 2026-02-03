# Data Modeling Demo with Apache Pinot

## Overview
This repository demonstrates basic data modeling concepts using a simple e-commerce scenario with Apache Pinot as the analytical database.

## 🏗️ **Data Model Design**

### Star Schema Architecture
```
    Time Dimension
          │
          ▼
Customer ──┤ SALES_FACT ├── Product
          ▲              
          │              
    Store Dimension      
```

## 📊 **Tables Structure**

### Fact Table
- **sales_transactions** - Core business events (orders, revenue, quantities)

### Dimension Tables
- **dim_customers** - Customer master data
- **dim_products** - Product catalog
- **dim_stores** - Store/location information  
- **dim_time** - Calendar and date hierarchy

## 🚀 **Getting Started**

### Prerequisites
- Apache Pinot cluster running
- Sample data files in `/data` directory
- SQL scripts in `/sql` directory

### Quick Setup
1. Create tables using SQL scripts
2. Load sample data
3. Run analytical queries

## 📁 **Repository Structure**
```
data-modeling-demo/
├── sql/           # Table creation scripts
├── data/          # Sample CSV data files
├── configs/       # Pinot table configurations
├── docs/          # Additional documentation
└── README.md      # This file
```

## 🎯 **Key Learning Points**
- Star schema design principles
- Fact vs Dimension table patterns
- Apache Pinot implementation
- Sample analytical queries
- Performance optimization techniques
