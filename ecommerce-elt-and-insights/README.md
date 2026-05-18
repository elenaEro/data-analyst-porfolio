# E-COMMERCE SITE DATA ANALYTICS

## Uploading files with raw data to BigQuery

Uploaded the Olist Brazilian E-Commerce dataset using:
- Kaggle API to download the data
- Google Colab + Python to upload to BigQuery

- Dataset 1: https://www.kaggle.com/olistbr/brazilian-ecommerce
- Dataset 2: https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist

[Google Colab file](https://github.com/elenaEro/data-analyst-porfolio/blob/main/ecommerce-elt-and-insights/bquery_files_uploading.ipynb)

## Data Cleaning & Preparation

## Overview

The analysis is based on a B2B2C marketplace dataset covering the period from June 2017 to November 2018. The raw data consisted of four source tables: MQL records, closed deals, orders, and order items. The preparation process involved three layers: staging (cleaning individual tables), aggregation (summarising order data at seller level), and a final analytical table combining all sources.

---

## Source Tables

- **mqls** - records of all marketing qualified leads with origin, landing page, and contact date
- **closed_deals** - information on won deals including SDR/SR assignment, business type, and won date
- **orders** - individual order records with status and purchase dates
- **order_items** - line items within each order including item price and freight value

---

## Staging Layer

Each source table was cleaned independently before joining.

### Orders & Order Items

- Freight value was separated from item price. GMV is calculated as the sum of item prices only, excluding freight, as freight represents a logistics cost rather than merchandise value
- Order statuses were standardised. Only two statuses were retained for analysis: `delivered` (completed transactions) and `canceled` (failed transactions). Other intermediate statuses such as `shipped` and `invoiced` were excluded as they do not represent a final transaction outcome
- Orders were aggregated at seller level producing one row per seller with total delivered orders, total canceled orders, total GMV, cancellation rate, AOV, and first/last order dates for both delivered and canceled orders

### MQLs & Closed Deals

- MQL records were joined with closed deal information to enrich each lead with post-conversion attributes where available
- `business_type`, `sdr_id`, `sr_id`, `won_date` and other deal-level fields are only populated for converted sellers. This is an intentional data characteristic, not a gap, as these fields are captured at the deal stage

---

## Final Analytical Table: fct_funnel

A single analytical table `fct_funnel` was created joining the enriched MQL view with the seller-level orders summary via a LEFT JOIN on `seller_id`. The table contains one row per MQL, 8,000 records total, preserving all leads regardless of conversion status.

### Key Derived Fields

| Field | Description |
|---|---|
| `is_won` | Binary flag, 1 if the MQL converted to a seller |
| `activated` | Binary flag, 1 if the won seller placed at least one delivered order |
| `sales_cycle_days` | Days between first contact date and won date |
| `days_to_activation` | Days between won date and first delivered order |
| `canc_rate` | Canceled orders / (delivered + canceled orders) |
| `aov` | GMV / delivered orders, NULL for sellers with no delivered orders |
| `gmv_tier` | Quartile-based seller segmentation (Q1 Low, Q2 Medium, Q3 High, Q4 Top) calculated using PERCENTILE_CONT to ensure boundaries fall between real data points |

---

## Data Quality Findings

### Null Values

- `declared_monthly_revenue` has an 89% null rate. This field was only captured for a small subset of leads and was excluded from segmentation analysis
- `business_type`, `sdr_id`, and other deal-level fields are null for all non-converted MQLs by design. These are post-conversion attributes not available at the MQL stage
- All order-related fields (GMV, AOV, cancellation rate) are null for non-converted and non-activated sellers. This is expected and intentional

### Zombie Sellers

465 won sellers have no corresponding order data. They signed contracts but never placed a single order on the platform. These sellers are counted in MQL to Won conversion metrics but excluded from Won to Activated rate calculations and post-conversion quality analysis.

### Negative Sales Cycle

One record was identified with a sales cycle of -2 days, meaning the won date preceded the first contact date. This is attributed to a CRM data entry error. The `sales_cycle_days` field was set to NULL for this record. It remains included in all conversion metrics.

### Data Coverage Gap

Won dates extend to November 2018 but order activity stops in August 2018. Sellers won after August 2018 had no opportunity to activate within the dataset window. These sellers are included in conversion metrics but excluded from activation rate calculations to avoid artificially deflating the won to activated rate.

### Join Coverage

The orders dataset contains 3,021 distinct seller IDs compared to 842 won sellers in the funnel table. The additional sellers in the orders data represent merchants onboarded through channels outside the MQL funnel or prior to the MQL tracking system being implemented.

---

## Limitations

- No intermediate funnel stage timestamps are available. Only first contact date and won date exist. Sales cycle length represents total time from first touch to close with no visibility into individual stage durations
- Landing page IDs are UUIDs with no associated metadata. Page content and intent cannot be inferred from the data alone
- The dataset covers a relatively short window of order activity (January to August 2018), limiting the depth of post-conversion seller behaviour analysis
- 495 distinct landing pages were identified but 87% have fewer than 20 MQLs. Only 64 pages meet the minimum threshold for reliable conversion rate analysis
# Data Cleaning & Preparation

## Overview

The analysis is based on a B2B2C marketplace dataset covering the period from June 2017 to November 2018. The raw data consisted of four source tables: MQL records, closed deals, orders, and order items. The preparation process involved three layers: staging (cleaning individual tables), aggregation (summarising order data at seller level), and a final analytical table combining all sources.

---

## Source Tables

- **mqls** - records of all marketing qualified leads with origin, landing page, and contact date
- **closed_deals** - information on won deals including SDR/SR assignment, business type, and won date
- **orders** - individual order records with status and purchase dates
- **order_items** - line items within each order including item price and freight value

---

## Staging Layer

Each source table was cleaned independently before joining.

### Orders & Order Items

- Freight value was separated from item price. GMV is calculated as the sum of item prices only, excluding freight, as freight represents a logistics cost rather than merchandise value
- Order statuses were standardised. Only two statuses were retained for analysis: `delivered` (completed transactions) and `canceled` (failed transactions). Other intermediate statuses such as `shipped` and `invoiced` were excluded as they do not represent a final transaction outcome
- Orders were aggregated at seller level producing one row per seller with total delivered orders, total canceled orders, total GMV, cancellation rate, AOV, and first/last order dates for both delivered and canceled orders

### MQLs & Closed Deals

- MQL records were joined with closed deal information to enrich each lead with post-conversion attributes where available
- `business_type`, `sdr_id`, `sr_id`, `won_date` and other deal-level fields are only populated for converted sellers. This is an intentional data characteristic, not a gap, as these fields are captured at the deal stage

---

## Final Analytical Table: fct_funnel

A single analytical table `fct_funnel` was created joining the enriched MQL view with the seller-level orders summary via a LEFT JOIN on `seller_id`. The table contains one row per MQL, 8,000 records total, preserving all leads regardless of conversion status.

### Key Derived Fields

| Field | Description |
|---|---|
| `is_won` | Binary flag, 1 if the MQL converted to a seller |
| `activated` | Binary flag, 1 if the won seller placed at least one delivered order |
| `sales_cycle_days` | Days between first contact date and won date |
| `days_to_activation` | Days between won date and first delivered order |
| `canc_rate` | Canceled orders / (delivered + canceled orders) |
| `aov` | GMV / delivered orders, NULL for sellers with no delivered orders |
| `gmv_tier` | Quartile-based seller segmentation (Q1 Low, Q2 Medium, Q3 High, Q4 Top) calculated using PERCENTILE_CONT to ensure boundaries fall between real data points |

---

## Data Quality Findings

### Null Values

- `declared_monthly_revenue` has an 89% null rate. This field was only captured for a small subset of leads and was excluded from segmentation analysis
- `business_type`, `sdr_id`, and other deal-level fields are null for all non-converted MQLs by design. These are post-conversion attributes not available at the MQL stage
- All order-related fields (GMV, AOV, cancellation rate) are null for non-converted and non-activated sellers. This is expected and intentional

### Zombie Sellers

465 won sellers have no corresponding order data. They signed contracts but never placed a single order on the platform. These sellers are counted in MQL to Won conversion metrics but excluded from Won to Activated rate calculations and post-conversion quality analysis.

### Negative Sales Cycle

One record was identified with a sales cycle of -2 days, meaning the won date preceded the first contact date. This is attributed to a CRM data entry error. The `sales_cycle_days` field was set to NULL for this record. It remains included in all conversion metrics.

### Data Coverage Gap

Won dates extend to November 2018 but order activity stops in August 2018. Sellers won after August 2018 had no opportunity to activate within the dataset window. These sellers are included in conversion metrics but excluded from activation rate calculations to avoid artificially deflating the won to activated rate.

### Join Coverage

The orders dataset contains 3,021 distinct seller IDs compared to 842 won sellers in the funnel table. The additional sellers in the orders data represent merchants onboarded through channels outside the MQL funnel or prior to the MQL tracking system being implemented.

---

## Limitations

- No intermediate funnel stage timestamps are available. Only first contact date and won date exist. Sales cycle length represents total time from first touch to close with no visibility into individual stage durations
- Landing page IDs are UUIDs with no associated metadata. Page content and intent cannot be inferred from the data alone
- The dataset covers a relatively short window of order activity (January to August 2018), limiting the depth of post-conversion seller behaviour analysis
- 495 distinct landing pages were identified but 87% have fewer than 20 MQLs. Only 64 pages meet the minimum threshold for reliable conversion rate analysis
