/*
=====================================================
OLIST E-COMMERCE ANALYTICS PROJECT
=====================================================

Author: Mert Dal
Tools: MySQL, Tableau
Dataset: Olist Brazilian E-commerce Dataset
Project Type: Customer & Revenue Analytics

Description:
This project analyzes customer behavior, revenue drivers,
and retention patterns in a Brazilian e-commerce platform.

Key Business Questions:
1. Is the business growing over time?
2. Which customers generate the most revenue?
3. Which product categories drive revenue?
4. Is there a retention problem?
5. How concentrated is revenue among customers?

Main Analyses:
• Revenue metrics
• Product category performance
• Customer revenue concentration (Pareto)
• Purchase frequency distribution
• Cohort retention analysis

=====================================================
SQL PIPELINE STRUCTURE
=====================================================

SECTION 1  Database Setup
SECTION 2  Data Import
SECTION 3  Data Validation
SECTION 4  Core Business Metrics
SECTION 5  Customer Behavior Analysis
SECTION 6  Revenue Analysis
SECTION 7  Tableau Analytics Views
SECTION 8  Key Insights

*/


-- =====================================================
-- SECTION 1 DATABASE SETUP
-- Create database and configure SQL environment
-- =====================================================

-- SQL mode setup for the analysis
SET sql_mode =
'ONLY_FULL_GROUP_BY,STRICT_ALL_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- Create new database
CREATE DATABASE Olist;

-- Use the created database
USE Olist;



-- =====================================================
-- SECTION 2 DATA IMPORT
-- Create tables and import raw CSV datasets
-- =====================================================

CREATE TABLE customers (
customer_id VARCHAR(255),
customer_unique_id VARCHAR(255),
customer_zip_code_prefix INT,
customer_city VARCHAR(255),
customer_state VARCHAR(255)
);

LOAD DATA LOCAL INFILE '/Users/mert/Downloads/Olist/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


CREATE TABLE order_items (
order_id VARCHAR(255),
order_item_id VARCHAR(255),
product_id VARCHAR(255),
seller_id VARCHAR(255),
shipping_limit_date DATETIME,
price FLOAT,
freight_value FLOAT,
PRIMARY KEY(order_id, order_item_id)
);

LOAD DATA LOCAL INFILE '/Users/mert/Downloads/Olist/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


CREATE TABLE order_payments (
order_id VARCHAR(255),
payment_sequential VARCHAR(255),
payment_type VARCHAR(255),
payment_installments INT,
payment_value FLOAT
);

LOAD DATA LOCAL INFILE '/Users/mert/Downloads/Olist/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


CREATE TABLE orders(
order_id VARCHAR(32) PRIMARY KEY,
customer_id VARCHAR(32),
order_status VARCHAR(20),
order_purchase_timestamp DATETIME,
order_approved_at DATETIME,
order_delivered_carrier_date DATETIME,
order_delivered_customer_date DATETIME,
order_estimated_delivery_date DATETIME
);

LOAD DATA LOCAL INFILE '/Users/mert/Downloads/Olist/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
order_id,
customer_id,
order_status,
@order_purchase_timestamp,
@order_approved_at,
@order_delivered_carrier_date,
@order_delivered_customer_date,
@order_estimated_delivery_date
)
SET
order_purchase_timestamp = NULLIF(@order_purchase_timestamp,''),
order_approved_at = NULLIF(@order_approved_at,''),
order_delivered_carrier_date = NULLIF(@order_delivered_carrier_date,''),
order_delivered_customer_date = NULLIF(@order_delivered_customer_date,''),
order_estimated_delivery_date = NULLIF(@order_estimated_delivery_date,'');


CREATE TABLE products(
product_id VARCHAR(255),
product_category_name VARCHAR(255),
product_name_lenght FLOAT,
product_description_lenght FLOAT,
product_photos_qty FLOAT,
product_weight_g FLOAT,
product_length_cm FLOAT,
product_height_cm FLOAT,
product_width_cm FLOAT
);

LOAD DATA LOCAL INFILE '/Users/mert/Downloads/Olist/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
product_id,
product_category_name,
@product_name_lenght,
@product_description_lenght,
@product_photos_qty,
@product_weight_g,
@product_length_cm,
@product_height_cm,
@product_width_cm
)
SET
product_name_lenght = NULLIF(@product_name_lenght,''),
product_description_lenght = NULLIF(@product_description_lenght,''),
product_photos_qty = NULLIF(@product_photos_qty,''),
product_weight_g = NULLIF(@product_weight_g,''),
product_length_cm = NULLIF(@product_length_cm,''),
product_height_cm = NULLIF(@product_height_cm,''),
product_width_cm = NULLIF(@product_width_cm,'');


CREATE INDEX idx_orders_customer
ON orders(customer_id);

CREATE INDEX idx_orders_order
ON orders(order_id);

CREATE INDEX idx_customers_customer
ON customers(customer_id);



-- =====================================================
-- SECTION 3 DATA VALIDATION
-- Basic sanity checks after data import
-- =====================================================

-- Sanity check for import tables
SELECT COUNT(*) from orders;
-- 99441 rows
SELECT COUNT(*) from customers;
-- 99441 rows
SELECT COUNT(*) from order_items;
-- 112650 rows
SELECT COUNT(*) from order_payments;
-- 103886 rows
SELECT COUNT(*) from products;
-- 32951 rows

-- -----------------------------------------------------
-- Dataset Summary
-- orders: 99k
-- customers: 99k
-- order_items: 112k
-- payments: 103k
-- products: 32k

-- -----------------------------------------------------
-- Order Status Distribution
SELECT 
	order_status,
    count(*) AS order_count
FROM 
	orders
GROUP BY
	order_status;



-- =====================================================
--  SECTION 4 CORE BUSINESS METRICS
-- High-level revenue and order metrics
-- =====================================================

-- -----------------------------------------------------
-- Calculate Total Revenue
CREATE VIEW order_payments_grouped AS 
SELECT
	order_id,
    SUM(payment_value) as sum_payment_value
FROM 
	order_payments
GROUP BY
	order_id;
    
    SELECT
		ROUND(SUM(p.sum_payment_value),0) as total_revenue
	FROM 
		orders o 
			JOIN order_payments_grouped p ON 
				o.order_id = p.order_id
	WHERE
		order_status = 'delivered';
        
-- -----------------------------------------------------
-- Calculate Average Order Value (AOV)	
    SELECT
		ROUND(SUM(p.sum_payment_value) / COUNT(DISTINCT o.order_id),2) as average_order_value
	FROM 
		orders o 
			JOIN order_payments_grouped p ON 
				o.order_id = p.order_id
	WHERE
		order_status = 'delivered';
	


-- =====================================================
-- SECTION 5 Customer Behaviour Analysis
-- Understanding customer purchase patterns
-- =====================================================

-- -----------------------------------------------------
-- COHORT RETENTION ANALYSIS

-- Business Question:
-- Do customers return after their first purchase?

CREATE VIEW cohort_month AS
SELECT
	c.customer_unique_id,
    DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS first_purchase_month,
	MIN(o.order_purchase_timestamp) AS first_purchase_month_datetime
	
FROM 
	orders o
		JOIN customers c
			ON o.customer_id = c.customer_id
 WHERE
	order_purchase_timestamp IS NOT NULL
GROUP BY
	c.customer_unique_id;

CREATE VIEW order_month AS
SELECT
	c.customer_unique_id,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
	o.order_purchase_timestamp AS purchase_month_datetime
FROM 
	orders o
		JOIN customers c
			ON o.customer_id = c.customer_id
 WHERE
	o.order_purchase_timestamp IS NOT NULL;
            
SELECT
    c.first_purchase_month AS cohort_month,
    o.purchase_month AS order_month,
    TIMESTAMPDIFF(
    MONTH,
	DATE_FORMAT(c.first_purchase_month_datetime,'%Y-%m-01'),  
    DATE_FORMAT(o.purchase_month_datetime,'%Y-%m-01')) as month_number,
    COUNT(DISTINCT c.customer_unique_id) as customers
FROM order_month o
	JOIN cohort_month c
		ON o.customer_unique_id = c.customer_unique_id
GROUP BY 
	cohort_month,order_month, month_number
ORDER BY 
	cohort_month,order_month;
    
    
-- -----------------------------------------------------
-- Retention Calculation for Cohort map

CREATE VIEW vw_cohort_retention AS
SELECT
	cohort_month,
	order_month,
    month_number,
    customers / MAX(customers) OVER(PARTITION BY cohort_month) as retention_perc
FROM (
SELECT
    c.first_purchase_month AS cohort_month,
    o.purchase_month AS order_month,
    TIMESTAMPDIFF(
    MONTH,
	DATE_FORMAT(c.first_purchase_month_datetime,'%Y-%m-01'),  
    DATE_FORMAT(o.purchase_month_datetime,'%Y-%m-01')) as month_number,
    COUNT(DISTINCT c.customer_unique_id) as customers

FROM order_month o
	JOIN cohort_month c
		ON o.customer_unique_id = c.customer_unique_id
GROUP BY 
	cohort_month,order_month, month_number
) t
ORDER BY 
	cohort_month, 
    month_number;
    
    
-- -----------------------------------------------------
-- Purchase Frequency Distribution

SELECT
	orders,
    count(*) as customers
FROM
	(SELECT
		c.customer_unique_id,
		count(*) as orders
	FROM
		customers c
			JOIN orders o
				ON o.customer_id = c.customer_id
	GROUP BY
		c.customer_unique_id) t
GROUP BY
	orders
ORDER BY
	orders; 
    
    
-- -----------------------------------------------------
-- Repeat vs One-Time Customer Revenue

CREATE VIEW customer_repetition_segment_vw AS 
SELECT
	c.customer_unique_id,
	count(o.order_id) as orders,
    CASE 
		WHEN count(o.order_id) = 0 THEN 'Non-Order Customer'
		WHEN count(o.order_id) = 1 THEN 'One-Time Customer'
		ELSE 'Repetitive Customer' 
	END as customer_repetition_segment
FROM
	customers c
		LEFT JOIN orders o
			ON o.customer_id = c.customer_id
            AND o.order_status = 'delivered'
GROUP BY
	c.customer_unique_id;

SELECT
	customer_repetition_segment as segment,
    COUNT(DISTINCT c.customer_unique_id) as customers,
    IFNULL(ROUND(SUM(sum_payment_value),0),0) as revenue,
	ROUND(IFNULL(ROUND(SUM(sum_payment_value),0),0) / COUNT(DISTINCT c.customer_unique_id),0) revenue_per_customer
FROM
	customers c
		LEFT JOIN customer_repetition_segment_vw crsw
			ON c.customer_unique_id = crsw.customer_unique_id
		LEFT JOIN orders o
			ON c.customer_id = o.customer_id
            AND o.order_status = 'delivered'
		LEFT JOIN order_payments_grouped opg
			ON o.order_id = opg.order_id
GROUP BY
	 customer_repetition_segment;
-- 2738 Non-Order Customers
    
    
-- Sanity Check for Non-Order customers
SELECT
	COUNT(DISTINCT customer_unique_id )- COUNT(DISTINCT CASE WHEN order_id IS NOT NULL THEN customer_unique_id ELSE NULL END) AS non_prder_customers
FROM
	customers c
		LEFT JOIN
			orders o 
				ON c.customer_id = o.customer_id
                AND o.order_status = 'delivered';                
-- 2738 Non-Order Customers. Validated



-- =====================================================
-- SECTION 6 Revenue ANALYSIS
-- Identifying key sources of revenue
-- =====================================================


-- -----------------------------------------------------
-- PRODUCT CATEGORY REVENUE

-- Business Question:
-- Which product categories drive the most revenue?

    CREATE VIEW vw_category_revenue AS
    SELECT
		p.product_category_name AS category,
        ROUND(SUM(price + freight_value),0) AS category_Revenue
	FROM 
		order_items oi
			JOIN products p 
				ON p.product_id = oi.product_id
			JOIN orders o
				ON o.order_id = oi.order_id
	WHERE
		o.order_status = 'delivered'
	GROUP BY 
		p.product_category_name
	ORDER BY
		category_revenue DESC;
        
        
-- -----------------------------------------------------
-- REVENUE TREND OVER TIME

-- Business Question: 
-- Is the business growing over time?

SELECT
	DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    ROUND(SUM(sum_payment_value),0) AS revenue
FROM 
	orders o
		JOIN order_payments_grouped opg
			ON o.order_id = opg.order_id
WHERE
	o.order_status = 'delivered' 
    AND order_purchase_timestamp IS NOT NULL
GROUP BY
	order_month
ORDER BY 
	order_month;
    
    
-- -----------------------------------------------------
-- CUSTOMER REVENUE CONCENTRATION (PARETO ANALYSIS)

-- Business Question:
-- How concentrated is revenue among customers?

CREATE VIEW customer_pareto_analysis AS 
SELECT
	c.customer_unique_id AS customer,
    ROUND(SUM(opg.sum_payment_value),1) AS customer_total_revenue
FROM 
	customers c
		JOIN orders o
			ON o.customer_id = c.customer_id
            AND o.order_status = 'delivered'
		JOIN order_payments_grouped opg
			ON opg.order_id = o.order_id
GROUP BY
	c.customer_unique_id;


CREATE VIEW perc_rolling_vw AS
 SELECT
	ntile_ranking,
    SUM(customer_total_revenue) OVER(ORDER BY customer_total_revenue DESC) 
    / SUM(customer_total_revenue) OVER() as perc_rolling_revenue
FROM(
	SELECT
		customer_total_revenue,
		NTILE(20) OVER(ORDER BY customer_total_revenue DESC) as ntile_ranking
	FROM
		customer_pareto_analysis) t;


CREATE VIEW vw_pareto_analysis AS
SELECT
	ntile_ranking * 5  as top_customer_percentage,
    ROUND(MAX(perc_rolling_revenue),2) AS revenue_share
FROM
	perc_rolling_vw
GROUP BY
	ntile_ranking;
-- %54 of revenue comes from top %20 percent of customers.
-- Top 20% of customers generate 54% of total revenue, indicating moderate revenue concentration.
-- Generally, 20% customers → 60-80% revenue would be expected.


-- =====================================================
-- SECTION 7 — ANALYTICS DATASETS FOR TABLEAU
-- Clean analytical views used for dashboarding
-- =====================================================

CREATE VIEW vw_orders_analytics AS
SELECT
    o.order_id,
    c.customer_unique_id,
    DATE(o.order_purchase_timestamp) AS order_date,
    DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') AS order_month,
    o.order_status,
    SUM(opg.sum_payment_value) AS order_revenue
FROM orders o
	JOIN customers c
		ON o.customer_id = c.customer_id
	JOIN order_payments_grouped opg
		ON o.order_id = opg.order_id
WHERE 
	o.order_status = 'delivered'
GROUP BY
	o.order_id,
	c.customer_unique_id,
	order_date,
	order_month,
	o.order_status;
    
/*
The following analytical views are used as data sources for the Tableau dashboard.

Tableau Views:

1. vw_orders_analytics
   → Order-level analytics dataset
   → Used for:
     - Revenue trend
     - KPI metrics

2. vw_category_revenue
   → Revenue contribution by product category
   → Used for:
     - Top Revenue Driving Categories chart

3. vw_cohort_retention
   → Cohort retention percentages
   → Used for:
     - Cohort retention heatmap

4. vw_pareto_analysis
   → Customer revenue concentration analysis
   → Used for:
     - Pareto (Revenue Concentration) chart
*/
        

-- =====================================================
-- SECTION 8 KEY INSIGHTS
-- Summary of analytical findings
-- =====================================================

/*
• Revenue grew steadily throughout 2017
  → Identify growth drivers and scale successful channels

• Top 20% of customers generate ~54% of revenue
  → Retain high-value customers with loyalty programs

• ~97% of customers make only one purchase
  → Encourage repeat purchases via targeted promotions

• Retention drops sharply after first purchase
  → Improve post-purchase engagement and onboarding
*/


