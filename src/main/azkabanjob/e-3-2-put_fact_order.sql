INSERT INTO  fact_sales_order partition(order_date)
select tmp.*,${hiveconf:pre_date} order_date from tmp;