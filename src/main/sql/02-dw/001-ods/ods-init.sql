	-- 连接hive

	-- 库若存在就删除，且删除该库下所有的表 (级联删除)
	drop database if exists sales_rds cascade;

	-- 创建rds库
	create database if not exists sales_rds;

	use sales_rds;

	-- 创建表
	/*==============================================================*/
	/* Table: customer                                              */
	/*==============================================================*/
CREATE TABLE customer(
customer_number INT,
customer_name VARCHAR(128),
customer_street_address VARCHAR(255),
customer_zip_code INT,
customer_city VARCHAR(32),
customer_state VARCHAR(32)
)
row format delimited fields terminated by '\t'
stored as textfile;

	/*==============================================================*/
	/* Table: product                                               */
	/*==============================================================*/
CREATE TABLE  if not exists product
(
product_code         INT,
product_name         VARCHAR(128)  ,
product_category     VARCHAR(256)
);

	/*==============================================================*/
	/* Table: sales_order                                           */
	/*==============================================================*/
CREATE TABLE if not exists sales_order
(
order_number         INT ,
customer_number      INT,
product_code         INT ,
order_date           timestamp  ,
entry_date           timestamp  ,
order_amount         DECIMAL(18,2)
)
row format delimited fields terminated by '\t' ;
