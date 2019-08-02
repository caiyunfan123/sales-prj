create table if not exists month_sales_combine_top10(
product_sk1 int,
product_sk2 int,
total int
)

insert into month_sales_combine_top10
select t1.product_sk,t2.product_sk,count(1) from dim_date t1
join com_sales_order t2
on t1.date_sk=t2.date_sk and t1.year=year(${input_year}) and t1.month = month(${input_month})
group by t1.product_sk,t2.product_sk
order by count(1) desc
limit 10;