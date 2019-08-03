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
select customer_number,
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
product_code,
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
order_number,
order_number, 
1, 
order_date, 
'2050-01-01'
FROM sales_rds.sales_order;


-- 装载销售订单事实表
INSERT into sales_dw.fact_sales_order partition(order_date='2019-07-31')
-- 加一条测试数据
insert into fact_sales_order partition(order_date='2019-07-31') values(1000,6,1,4184,1000);

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

--装载商品组合表
insert into com_sales_order partition(order_date='2019-07-31')
select t1.order_date_sk,t1.customer_sk,t1.order_sk,t1.product_sk,t1.order_amount,t2.product_sk,t2.order_amount
from sales_dw.fact_sales_order t1 join sales_dw.fact_sales_order t2
on t1.order_sk=t2.order_sk
where t1.product_sk<t2.product_sk;