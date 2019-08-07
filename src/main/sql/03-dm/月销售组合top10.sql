--经过数据实测，成功。

create table if not exists month_sales_combine_top10(
c_year int,
c_month int,
product_sk1 int,
product_sk2 int,
total int
)

insert into sales_dm.month_sales_combine_top10
select t1.year,t1.month,
t2.product_sk1,t2.product_sk2,count(1) total from dim_date t1
join com_sales_order t2
on t1.date_sk=t2.date_sk and t1.year=${input_year} and t1.month = ${input_month}
group by t1.year,t1.month,t2.product_sk1,t2.product_sk2
order by total desc
limit 10;