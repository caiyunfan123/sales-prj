UPDATE dim_product
SET expiry_date = ${hiveconf:pre_date}
WHERE dim_product.product_sk IN(SELECT a.product_sk
FROM(SELECT product_sk,
product_code,
product_name,
product_category
FROM dim_product
WHERE expiry_date = ${hiveconf:max_date}) a
LEFT JOIN sales_rds.product b ON a.product_code = b.product_code
WHERE b.product_code IS NULL
OR (a.product_name <> b.product_name OR a.product_category <> b.product_category));