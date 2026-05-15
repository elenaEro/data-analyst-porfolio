#check total rows in raw table
SELECT COUNT(*)--112650
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`;

#check nulls in all columns
SELECT
  SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS nulls_order_id,
  SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) AS nulls_item_id,
  SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS nulls_product_id,
  SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS nulls_seller_id,
  SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) AS nulls_shipping_limit_date,
  SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS price,
  SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS nulls_freight_value
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`;
#no nulls in the table

#check for trimming issues in string columns
SELECT COUNT(*)
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`
WHERE order_id != TRIM(order_id);

SELECT COUNT(*)
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`
WHERE product_id != TRIM(product_id);

SELECT COUNT(*)
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`
WHERE seller_id != TRIM(seller_id);

#no trimming is required

#check date range of date/numerical columns (item_id must be cast as string)
SELECT MIN(shipping_limit_date), MAX(shipping_limit_date),--max is 2020-04-09 for the orders made 2016-2018
      MIN(price), MAX(price),--0.85 - 6735.0
      MIN(freight_value), MAX(freight_value), -- 0 - 409.68, is it possible to have 0 freight expenses?
      MIN(order_item_id), MAX(order_item_id) -- 1-21 in 1 order seem to be reasonable
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`;

SELECT COUNT(*)
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`
WHERE shipping_limit_date > '2018-10-17';--(last order in dataset), 4rows

SELECT COUNT(*)
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`
WHERE shipping_limit_date > '2018-12-31';--4

SELECT i.*, o.order_status, o.order_purchase_date, 
       o.order_delivered_customer_date
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items` i
LEFT JOIN `project-f1e6afa5-5311-4b6e-94e.ecom.orders` o
USING(order_id)
WHERE i.shipping_limit_date > '2018-12-31';
# 4 rows with shipping_limit_date after 2018-12-31 cross-referenced with orders table:
# - 1 cancelled order, 1 shipped/undelivered order, 2 delivered orders in 2017 with 2020 shipping limit (data error)
# decision: replace all 4 with NULL
 
UPDATE `project-f1e6afa5-5311-4b6e-94e.ecom.items`
SET shipping_limit_date = NULL
WHERE shipping_limit_date > '2018-12-31';
#check the outcome
SELECT COUNT(*)
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`
WHERE shipping_limit_date > '2018-12-31';--0

#freight_value
SELECT COUNT(*)
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`
WHERE freight_value = 0; --383

SELECT freight_value, MIN(price), AVG(price), MAX(price)--54, 98, 712
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`
WHERE freight_value = 0
GROUP BY freight_value;

SELECT product_id,
SUM(CASE WHEN freight_value = 0 THEN 1 ELSE 0 END) AS free_freight_items,
SUM(CASE WHEN freight_value !=0 THEN 1 ELSE 0 END) AS paid_freight_items
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`
GROUP BY product_id
HAVING free_freight_items > 0;
# 383 rows with freight_value = 0 investigated, all products with free freight also have paid freight orders, some products have only 1 free freight occurrence which may indicate a one-time promotion, data entry error, or test order
# We'll keep 0 values for now pending clarification from business on how free shipping promotions are applied

#Let's check the price outliers

WITH stats AS(
  SELECT i.product_id, i.price, p.product_category_name, PERCENTILE_CONT(price, 0.25) OVER(PARTITION BY product_category_name) AS q1,
  PERCENTILE_CONT(price, 0.75) OVER(PARTITION BY product_category_name) AS q3
  FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items` i
  LEFT JOIN `project-f1e6afa5-5311-4b6e-94e.ecom.products` p
  USING(product_id))
SELECT product_id, 
  price, 
  CASE WHEN price < q1 - 1.5*(q3 - q1) OR price > q3 + 1.5*(q3 - q1) THEN 'outlier' ELSE 'norm_range' END AS price_flag,
  s.product_category_name, product_category_name_english
FROM stats s
LEFT JOIN `project-f1e6afa5-5311-4b6e-94e.ecom.products_translation`
USING(product_category_name)
WHERE price < q1 - 1.5*(q3-q1) OR price > q3 + 1.5*(q3-q1); --9376 and 9268 with particular prod-cat-name, 108 with no product_category, overall around 8.3% of outliers, seem to be within the acceptable range.

#Check of product with no product_category_name:
SELECT COUNT(DISTINCT product_id)
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.products`
WHERE product_category_name IS NULL;--610 overall

#casting the date type:
ALTER TABLE `project-f1e6afa5-5311-4b6e-94e.ecom.items`
ADD COLUMN shipping_limit_date_n DATE;

UPDATE `project-f1e6afa5-5311-4b6e-94e.ecom.items`
SET shipping_limit_date_n = CAST(PARSE_DATETIME('%Y-%m-%d %H:%M:%S', shipping_limit_date) AS DATE)
WHERE TRUE;

#check the cast result

SELECT COUNT(*)    
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`
WHERE shipping_limit_date_n IS NULL; -- as after replacing 4 outliers

SELECT shipping_limit_date, shipping_limit_date_n
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`
LIMIT 10;

#drop old column and rename new one
ALTER TABLE `project-f1e6afa5-5311-4b6e-94e.ecom.items`
DROP COLUMN shipping_limit_date;

ALTER TABLE `project-f1e6afa5-5311-4b6e-94e.ecom.items`
RENAME COLUMN shipping_limit_date_n TO shipping_limit_date;

#the very last check
#check total rows in raw table
SELECT COUNT(*)--112650 as in raw data
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`;

#check nulls in all columns
SELECT
  SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS nulls_order_id,
  SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) AS nulls_item_id,
  SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS nulls_product_id,
  SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS nulls_seller_id,
  SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) AS nulls_shipping_limit_date,
  SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS price,
  SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS nulls_freight_value
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`;




