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
${hiveconf:pre_date} effective_date,
${hiveconf:max_date} expiry_date
FROM dim_product t1
INNER JOIN sales_rds.product t2 ON t1.product_code = t2.product_code
AND t1.expiry_date = ${hiveconf:pre_date}
LEFT JOIN dim_product t3 ON t1.product_code = t3.product_code
AND t3.expiry_date = ${hiveconf:max_date}
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
${hiveconf:pre_date},
${hiveconf:max_date}
FROM( SELECT t1.*
FROM sales_rds.product t1
LEFT JOIN dim_product t2 ON t1.product_code = t2.product_code
WHERE t2.product_sk IS NULL
) t;