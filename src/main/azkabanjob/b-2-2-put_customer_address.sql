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
${hiveconf:pre_date} effective_date,
${hiveconf:max_date} expiry_date
FROM dim_customer  t1
INNER JOIN sales_rds.customer t2 ON t1.customer_number = t2.customer_number
AND t1.expiry_date = ${hiveconf:pre_date}  --拿出所有过期数据 t1
WHERE t1.customer_street_address <> t2.customer_street_address  --排除掉相同的数据插入，只添加新数据。
) t;