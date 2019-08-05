insert into com_sales_order partition(order_date)
select t1.date_sk,t1.customer_sk,t1.order_sk,t1.product_sk,t1.order_amount,t2.product_sk,t2.order_amount,
${hiveconf:pre_date} order_date
from tmp t1 join tmp t2
on t1.order_sk=t2.order_sk
where t1.product_sk<t2.product_sk;