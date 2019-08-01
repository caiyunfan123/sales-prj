-- 装载客户维度表
/*INSERT INTO sales_dw.dim_customer (customer_sk,customer_number,customer_name,customer_street_address,customer_zip_code,customer_city,customer_state,`version`,effective_date,expiry_date)
SELECT
	row_number() over (ORDER BY t1.customer_number) + t2.sk_max,
	t1.customer_number, 
	t1.customer_name, 
	t1.customer_street_address,
	t1.customer_zip_code, 
	t1.customer_city, 
	t1.customer_state, 
	1,
	'2016-03-01', 
	'2050-01-01'
FROM sales_rds.customer t1
CROSS JOIN 
	(SELECT COALESCE(MAX(customer_sk),0) sk_max 
	FROM sales_dw.dim_customer) t2;*/
	
	
--装载日期表
insert into sales_dw.dim_date
select sales_rds.row_sequence(),date,month,month_name,quarter,year
from sales_rds.dim_date;

--装载客户表
insert into sales_dw.dim_customer
select sales_rds.row_sequence(),
customer_number,
customer_name,
customer_street_address,
customer_zip_code,
customer_city,
customer_state,
1,
'2016-03-01',
'2050-01-01'
from sales_rds.customer;

-- 装载产品维度表
INSERT INTO sales_dw.dim_product (product_sk,product_code,product_name,product_category,`version`,effective_date,expiry_date)
SELECT
sales_rds.row_sequence(),
product_code, 
product_name, 
product_category, 
1,
'2016-03-01', 
'2050-01-01'
FROM sales_rds.product;
	
-- 装载订单维度表
INSERT INTO sales_dw.dim_order(order_sk,order_number,`version`,effective_date,expiry_date)
SELECT
sales_rds.row_sequence(),
order_number, 
1, 
order_date, 
'2050-01-01'
FROM sales_rds.sales_order;


-- 装载销售订单事实表
INSERT into sales_dw.fact_sales_order partition(order_date='2019-07-31')
SELECT
order_sk,
customer_sk, 
product_sk, 
date_sk, 
order_amount
FROM sales_rds.sales_order a
JOIN sales_dw.dim_order b ON a.order_number = b.order_number
JOIN sales_dw.dim_customer c ON a.customer_number = c.customer_number
JOIN sales_dw.dim_product d ON a.product_code = d.product_code
JOIN sales_dw.dim_date e ON DATE_FORMAT(a.order_date,'yyyy-MM-dd') = e.`date`;