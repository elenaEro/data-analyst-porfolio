#Let's group the information about the order value and time to first order by each seller_id

# mergin orders and items tables

CREATE VIEW `project-f1e6afa5-5311-4b6e-94e.ecom.orders_items_merged` AS
WITH order_info AS (
  SELECT order_id, seller_id, SUM(price) as o_price
  FROM `project-f1e6afa5-5311-4b6e-94e.ecom.items`
  GROUP BY seller_id, order_id)

SELECT seller_id, 
  COUNT(CASE WHEN order_status = 'delivered' THEN order_id END) as t_orders_delivered,
  COUNT(CASE WHEN order_status = 'canceled' THEN order_id END) as t_orders_canceled, 
  ROUND(SUM(CASE WHEN order_status = 'delivered' THEN o_price END), 2) as t_price_delivered, 
  ROUND(SUM(CASE WHEN order_status = 'canceled' THEN o_price END), 2) as t_price_canceled,
  MIN(CASE WHEN order_status = 'delivered' THEN order_purchase_date END ) as first_order_date_delivered, 
  MAX(CASE WHEN order_status = 'delivered' THEN order_purchase_date END) as last_order_date_delivered,
  MIN(CASE WHEN order_status = 'canceled' THEN order_purchase_date END ) as first_order_date_canceled, 
  MAX(CASE WHEN order_status = 'canceled' THEN order_purchase_date END) as last_order_date_canceled
FROM order_info
LEFT JOIN `project-f1e6afa5-5311-4b6e-94e.ecom.orders`
USING(order_id)
WHERE order_status IN ('delivered', 'canceled')
GROUP BY seller_id
ORDER BY seller_id;