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
where DATE_FORMAT(T0.order_date,'yyyy-MM-dd')=${hiveconf:pre_date} 
and T0.entry_date >= rds_cdc.current_load        and T0.entry_date < rds_cdc.last_load
and T0.order_date >= dim_customer.effective_date and T0.order_date < dim_customer.expiry_date
and T0.order_date >= dim_product.effective_date  and T0.order_date < dim_product.expiry_date