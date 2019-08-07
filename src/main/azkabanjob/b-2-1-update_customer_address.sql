UPDATE dim_customer
SET expiry_date = ${hiveconf:pre_date}
WHERE dim_customer.customer_sk 
IN(SELECT
    a.customer_sk
  FROM (SELECT
          customer_sk,
          customer_number,
          customer_street_address
        FROM dim_customer
        WHERE expiry_date = ${hiveconf:max_date}) a  --先筛除之前已经标记为过期的数据，留下未过期数据
  LEFT JOIN sales_rds.customer b ON a.customer_number = b.customer_number
  WHERE b.customer_number IS NULL                   --通过左连接筛选出发生了变化的客户（源数据是今天的，维度表是昨天的，昨天有的今天没有就是变化了）
       OR a.customer_street_address <> b.customer_street_address
);