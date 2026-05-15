#Check the rows in the raw table

#check total rows in raw table
SELECT COUNT(*) --99441
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`;

#check duplicates in primary key
SELECT order_id, COUNT(*) --no duplicates
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
GROUP BY order_id
HAVING COUNT(*) > 1;

#check that all orders have only 1 status:
SELECT order_id, COUNT(DISTINCT(order_status))
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
GROUP BY order_id
HAVING COUNT(DISTINCT(order_status)) > 1; -- everything is correct

SELECT DISTINCT(order_id)
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`;
#check nulls in all columns
SELECT
  SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS nulls_order_id,
  SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS nulls_customer_id,
  SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS nulls_order_status,
  SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS order_purchase_timestamp,
  SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS order_approved_at,
  SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS order_delivered_carrier_date,
  SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS order_delivered_customer_date,
  SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS order_estimated_delivery_date
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`;

#order_approved_at - 160
#order_delivered_carrier_date - 1783
#order_delivered_customer_date - 2965
#nulls are less than 3% out of all orders, but they may represent orders that were never approved/shipped/delivered. Let's keep them as they're for now
# note: exclude nulls when calculating time duration metrics

#check the distiribution among different status
SELECT DISTINCT(order_status), COUNT(*) as total, COUNT(order_approved_at) as approved, COUNT(order_delivered_carrier_date) as carrier_date, COUNT(order_delivered_customer_date) as customer_date
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
GROUP BY order_status;

#check the category columns (STRING)

SELECT DISTINCT(order_status) --no duplicates because of formatting
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`;

SELECT COUNT(*) --no trimming is needeed
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_status != TRIM(order_status);

# check the duplicates because of formatting in order_id and customer_id:
SELECT COUNT(*) --no trimming is needeed
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_id != TRIM(order_id);

SELECT COUNT(*) --no trimming is needeed
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE customer_id != TRIM(customer_id);

#check date range of date columns
SELECT MIN(order_purchase_timestamp) as min_purchase_time, MAX(order_purchase_timestamp)as max_purchase_time,
MIN(order_approved_at) as min_appr_at, MAX(order_approved_at)as max_appr_at,
MIN(order_delivered_carrier_date) as min_carr_date, MAX(order_delivered_carrier_date)as max_carr_date,
MIN(order_delivered_customer_date) as min_cust_date, MAX(order_delivered_customer_date)as max_cust_date,
MIN(order_estimated_delivery_date) as min_est_del, MAX(order_estimated_delivery_date)as max_est_del,
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`;

#As we see some descrepancy in max of max_purchase_time(2018-10-17) and max_appr_at(2018-09-03), max_carr_date(2018-09-11), let's check the business logic of date columns.
# We want order_purchase_timestamp < order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date
#order_approved_at < order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date

SELECT COUNT(*) --0
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_purchase_timestamp > order_approved_at; 

SELECT COUNT(*) --166
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_purchase_timestamp > order_delivered_carrier_date;

#Let's check what are those 166 orders with wrong order_delivered_carrier_date:
SELECT * --166
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_purchase_timestamp > order_delivered_carrier_date;

#165 out of 166 orders were delivered and have reasonable order_delivered_customer_date, only one was shipped with 0 for order_delivered_customer_date. For our purpose I'll replace the wrong dates with nulls and keep all the rows in the table. We also need to raise a question about possible reasons for those mistakes.

SELECT COUNT(*) --1359
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_approved_at > order_delivered_carrier_date;

SELECT *
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_approved_at > order_delivered_carrier_date
ORDER BY order_approved_at
LIMIT 40;
-- the difference in timestamp could be sec/mins at the same date, so this could be a batch automated process.


SELECT COUNT(*) -- 61
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_approved_at > order_delivered_customer_date;

#61 very often both the carrier and the customer's data of delivery are bigger than the appr_at
SELECT COUNT(*) --61(the same as in previous query)
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_approved_at > order_delivered_customer_date AND order_approved_at > order_delivered_carrier_date;

SELECT * --12, not a big concern as the estimated date is hypothetical
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_approved_at > order_estimated_delivery_date;
#Let's keep for now those 1359rows (including 61 when order_approved_at is bigger than both order_delivered_customer_date and order_delivered_carrier_date, as this may reflect the automated batch process. Important: to keep this in mind when analysing the operational/shopping KPIs and also to investigate the process of approval, implement constrains on dates, etc)

#Changes of date-time columns: 
#1. replacing with nulls incorrect data for order_delivered_carrier_date and checking the results; 
#2. adding the new columns and populating them based on date-time columns
#4. checking the results are correct 
#5. deleting the old columns with date information 
#NB! In production project I'll use the staging and final tables instead of modifying the row table directly

UPDATE `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
SET order_delivered_carrier_date = NULL
WHERE order_purchase_timestamp > order_delivered_carrier_date;

SELECT COUNT(*) --1949(1783 + 166)
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_delivered_carrier_date IS NULL;

ALTER TABLE `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
ADD COLUMN order_purchase_date DATE,
ADD COLUMN order_approved_at_date DATE, 
ADD COLUMN order_delivered_carrier_date_n DATE, 
ADD COLUMN order_delivered_customer_date_n DATE, 
ADD COLUMN order_estimated_delivery_date_n DATE;

UPDATE `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
SET order_purchase_date = CAST(PARSE_DATETIME('%Y-%m-%d %H:%M:%S', order_purchase_timestamp) AS DATE),
    order_approved_at_date = CAST(PARSE_DATETIME('%Y-%m-%d %H:%M:%S', order_approved_at) AS DATE),
    order_delivered_carrier_date_n = CAST(PARSE_DATETIME('%Y-%m-%d %H:%M:%S', order_delivered_carrier_date) AS DATE),
    order_delivered_customer_date_n = CAST(PARSE_DATETIME('%Y-%m-%d %H:%M:%S', order_delivered_customer_date) AS DATE),
    order_estimated_delivery_date_n = CAST(PARSE_DATETIME('%Y-%m-%d %H:%M:%S', order_estimated_delivery_date) AS DATE)
    WHERE TRUE;

SELECT COUNT(*)    
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_purchase_date IS NULL;

SELECT COUNT(*)--160 as in raw data    
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_approved_at_date IS NULL;

SELECT COUNT(*)--1949 (after replacing wrong dates with nulls)   
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_delivered_carrier_date_n IS NULL;

SELECT COUNT(*)--2965 as in raw data  
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_delivered_customer_date_n IS NULL;

SELECT COUNT(*)--0 as in row data  
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
WHERE order_estimated_delivery_date_n IS NULL;

SELECT 
    order_purchase_timestamp, order_purchase_date,
    order_approved_at, order_approved_at_date,
    order_delivered_carrier_date, order_delivered_carrier_date_n,
    order_delivered_customer_date, order_delivered_customer_date_n,
    order_estimated_delivery_date, order_estimated_delivery_date_n
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
LIMIT 10;

ALTER TABLE `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
DROP COLUMN order_purchase_timestamp,
DROP COLUMN order_approved_at,
DROP COLUMN order_delivered_carrier_date,
DROP COLUMN order_delivered_customer_date,
DROP COLUMN order_estimated_delivery_date;

ALTER TABLE `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
RENAME COLUMN order_delivered_carrier_date_n to order_delivered_carrier_date,
RENAME COLUMN order_delivered_customer_date_n to order_delivered_customer_date,
RENAME COLUMN order_estimated_delivery_date_n to order_estimated_delivery_date;


#The very last check
SELECT COUNT(*) --99441 as in raw data
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`;

-- 2. final null check across all columns
SELECT
  SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulls,--0
  SUM(CASE WHEN order_purchase_date IS NULL THEN 1 ELSE 0 END) AS purchase_nulls,--0
  SUM(CASE WHEN order_approved_at_date IS NULL THEN 1 ELSE 0 END) AS approved_nulls,--160
  SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS carrier_nulls,--1949
  SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS customer_nulls,--2965
  SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS estimated_nulls--0
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`;

#This is aligned with changes made  order_delivered_carrier_date column

SELECT *
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
LIMIT 5;

SELECT MAX(order_purchase_date)as max_purchase_time,
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.orders`;

