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
${hiveconf:pre_date},
${hiveconf:max_date}
FROM( SELECT t1.*
FROM sales_rds.customer t1
LEFT JOIN dim_customer t2 ON t1.customer_number = t2.customer_number
WHERE t2.customer_sk IS NULL ) t;