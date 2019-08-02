/*
set hive.exec.mode.local.auto=true;
set hive.support.concurrency=true;
set hive.txn.manager=org.apache.hadoop.hive.ql.lockmgr.DbTxnManager;
set hive.strict.checks.cartesian.product=false;
set hive.mapred.mode=nonstrict;
set hive.exec.mode.local.auto.input.files.max=64;

-- 设置scd的生效时间和过期时间，SCD:缓慢变化维
SET hivevar.cur_date = CURRENT_DATE();
SET hivevar.pre_date = DATE_ADD(${hivevar.cur_date},-1);
SET hivevar.max_date = CAST('2050-01-01' AS DATE);
*/
-- 设置DB
use sales_dw;

-- sales_rds.cdc_time作用：记录本次进行数据同步的时间，后续进行判断时，所有的时间都需要在该范围之内进行。筛选掉超出此范围的表数据。
-- last_load→ end_date; current_load → start_date
-- 设置cdc的开始结束日期 (记录维度表，事实表变化的时间),cdc. 变化数据捕获
-- start_date date,end_date date。
-- INSERT overwrite TABLE sales_rds.cdc_time
-- SELECT last_load, ${hivevar.cur_date} current_load FROM sales_rds.cdc_time;
INSERT overwrite TABLE sales_rds.cdc_time
SELECT ${hivevar.max_date}, ${hivevar.pre_date} current_load ;--FROM sales_rds.cdc_time;


/*
维度表SCD2更新策略：首先先更新过期数据的过期时间，然后再基于过期时间插入新的未过期的数据
	一、更新过期数据的过期时间：
		1.sqoop覆盖导入有效数据到ods层的对应表中
		2.通过比对更新后的ods表，挑选出ods表没有的但是维度表中有的数据，更新过期时间为昨天
		3.（顾客表）挑选出两表的顾客地址不一样的数据，更新过期时间为昨天
		
	二、插入新数据：
		1.首先以刚才更新后的维度表为基础，拿出所有的过期数据 t1
		2.再将数据与ods层的源数据t2内连接
		3.最后t1的地址与t2的地址不一样的数据，就是我们要更新插入的最终数据了。
	
*/
-- 装载customer维度(RDBMS: flg 0→有效,1→冻结；sqoop 导入到ods层时可以带条件，flg=0)
-- 获取源数据中被删除的客户和地址发生改变的客户，将这些数据设置为过期时间，即当前时间的前一天
UPDATE dim_customer
SET expiry_date = ${hivevar.pre_date}
WHERE dim_customer.customer_sk 
IN(SELECT
    a.customer_sk
  FROM (SELECT
          customer_sk,
          customer_number,
          customer_street_address
        FROM dim_customer
        WHERE expiry_date = ${hivevar.max_date}) a  --先筛除之前已经标记为过期的数据，留下未过期数据
  LEFT JOIN sales_rds.customer b ON a.customer_number = b.customer_number
  WHERE b.customer_number IS NULL                   --通过左连接筛选出发生了变化的客户（源数据是今天的，维度表是昨天的，昨天有的今天没有就是变化了）
       OR a.customer_street_address <> b.customer_street_address
);


-- 将有地址变化的插入到dim_customer表，如果有相同数据存在有不过期的数据则不插入
INSERT INTO dim_customer
SELECT
t.customer_number,
t.customer_number,
t.customer_name,
t.customer_street_address,
t.customer_zip_code,
t.customer_city,
t.customer_state,
t.version,
t.effective_date,
t.expiry_date
FROM(SELECT
t2.customer_number customer_number,
t2.customer_name customer_name,
t2.customer_street_address customer_street_address,
t2.customer_zip_code,
t2.customer_city,
t2.customer_state,
t1.version + 1 `version`,
${hivevar.pre_date} effective_date,
${hivevar.max_date} expiry_date
FROM dim_customer  t1
INNER JOIN sales_rds.customer t2 ON t1.customer_number = t2.customer_number
AND t1.expiry_date = ${hivevar.pre_date}  --拿出所有过期数据 t1
WHERE t1.customer_street_address <> t2.customer_street_address  --排除掉相同的数据插入，只添加新数据。
) t;


/*维度表的SCD1更新策略：简单粗暴，先对比然后从ods中拿出变化的数据，然后把dw中的那部分数据删掉，再把变化的数据插入进去*/

-- 处理customer_name列上的scd1，覆盖
-- 不进行更新，将源数据中的name列有变化的数据提取出来，放入临时表
-- 将 dim_couster中这些数据删除、
-- 将临时表中的数据插入
DROP TABLE IF EXISTS tmp;
CREATE TABLE tmp AS
SELECT a.customer_sk,
a.customer_number,
b.customer_name,
a.customer_street_address,
a.customer_zip_code,
a.customer_city,
a.customer_state,
a.version,
a.effective_date,
a.expiry_date
FROM dim_customer a
JOIN sales_rds.customer b ON a.customer_number = b.customer_number
Where a.customer_name <> b.customer_name ;

-- 删除数据
DELETE FROM
dim_customer WHERE
dim_customer.customer_sk IN (SELECT customer_sk FROM tmp);

-- 插入数据
INSERT INTO dim_customer
SELECT * FROM tmp;


-- 处理新增的customer记录
INSERT INTO dim_customer
SELECT
t.customer_number,
t.customer_number,
t.customer_name,
t.customer_street_address,
t.customer_zip_code,
t.customer_city,
t.customer_state,
1,
${hivevar.pre_date},
${hivevar.max_date}
FROM( SELECT t1.*
FROM sales_rds.customer t1
LEFT JOIN dim_customer t2 ON t1.customer_number = t2.customer_number
WHERE t2.customer_sk IS NULL ) t;

-- 装载product维度
-- 取源数据中删除或者属性发生变化的产品，将对应
UPDATE dim_product
SET expiry_date = ${hivevar.pre_date}
WHERE dim_product.product_sk IN(SELECT a.product_sk
FROM(SELECT product_sk,
product_code,
product_name,
product_category
FROM dim_product
WHERE expiry_date = ${hivevar.max_date}) a
LEFT JOIN sales_rds.product b ON a.product_code = b.product_code
WHERE b.product_code IS NULL
OR (a.product_name <> b.product_name OR a.product_category <> b.product_category));

-- 处理product_name、product_category列上scd2的新增行
INSERT INTO dim_product
SELECT
t.product_sk,
t.product_code,
t.product_name,
t.product_category,
t.version,
t.effective_date,
t.expiry_date
FROM( SELECT
t1.product_sk,
t2.product_code product_code,
t2.product_name product_name,
t2.product_category product_category,
t1.version + 1 `version`,
${hivevar.pre_date} effective_date,
${hivevar.max_date} expiry_date
FROM dim_product t1
INNER JOIN sales_rds.product t2 ON t1.product_code = t2.product_code
AND t1.expiry_date = ${hivevar.pre_date}
LEFT JOIN dim_product t3 ON t1.product_code = t3.product_code
AND t3.expiry_date = ${hivevar.max_date}
WHERE(t1.product_name <> t2.product_name
OR t1.product_category <> t2.product_category)
AND t3.product_sk IS NULL
) t;

-- 处理新增的 product 记录
INSERT INTO dim_product
SELECT
t.product_code,
t.product_code,
t.product_name,
t.product_category,
1,
${hivevar.pre_date},
${hivevar.max_date}
FROM( SELECT t1.*
FROM sales_rds.product t1
LEFT JOIN dim_product t2 ON t1.product_code = t2.product_code
WHERE t2.product_sk IS NULL
) t;

/*增量导入维度表策略：比起SCD策略来说要简单得多，从ods表中拿出以上次更新时间为下限，当前更新时间为上限的数据即可*/

-- 装载order维度
INSERT INTO dim_order
SELECT t1.order_number,
t1.order_number,
t1.version,
t1.effective_date,
t1.expiry_date
FROM(SELECT order_number order_number,
1 `version`,
order_date effective_date,
'2050-01-01' expiry_date
FROM sales_rds.sales_order, sales_rds.cdc_time
WHERE entry_date >= last_load AND entry_date < current_load ) t1;


-- 装载销售订单事实表和销售商品组合表
-- 先把装载销售订单事实表的数据加载到临时表中
drop table if exists tmp;
create table tmp as 
select order_sk,
customer_sk,
product_sk,
date_sk,
order_amount
from sales_rds.cdc_time as rds_cdc
join sales_rds.sales_order as T0
join dim_order on
T0.order_number = dim_order.order_number
join dim_customer on
T0.order_number = dim_customer.customer_number
join dim_product on
T0.product_code = dim_product.product_code
join dim_date on
to_date(T0.order_date) = dim_date.`date`
where DATE_FORMAT(T0.order_date,'yyyy-MM-dd')=${hivevar.pre_date} 
and T0.entry_date >= rds_cdc.current_load        and T0.entry_date < rds_cdc.last_load
and T0.order_date >= dim_customer.effective_date and T0.order_date < dim_customer.expiry_date
and T0.order_date >= dim_product.effective_date  and T0.order_date < dim_product.expiry_date

--装载销售订单事实表
INSERT INTO  fact_sales_order partition(order_date)
select tmp.*,${hivevar.pre_date} order_date from tmp;

--装载销售商品组合表
insert into com_sales_order partition(order_date)
select t1.date_sk,t1.customer_sk,t1.order_sk,t1.product_sk,t1.order_amount,t2.product_sk,t2.order_amount,
${hivevar.pre_date} order_date
from tmp t1 join tmp t2
on t1.order_sk=t2.order_sk
where t1.product_sk<t2.product_sk;