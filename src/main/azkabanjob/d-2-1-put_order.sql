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