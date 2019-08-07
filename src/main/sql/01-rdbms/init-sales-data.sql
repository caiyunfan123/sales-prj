-- 创建存储过程
DROP PROCEDURE  IF EXISTS usp_generate_order_data;

DELIMITER //
CREATE PROCEDURE usp_generate_order_data()
BEGIN

    -- 删除临时表
	DROP TABLE IF EXISTS tmp_sales_order;
	-- 创建临时表
	CREATE TABLE tmp_sales_order AS SELECT * FROM sales_order;-- WHERE 1=0;
	SET @start_date := UNIX_TIMESTAMP('2018-1-1');
	SET @end_date := UNIX_TIMESTAMP('2018-11-23');
	SET @i := 1;
	WHILE @i<=1000 DO
		SET @customer_number := FLOOR(1+RAND()*6);
		SET @product_code := FLOOR(1+RAND()* 3);
		SET @order_date := FROM_UNIXTIME(@start_date+RAND()*(@end_date-@start_date));
		SET @amount := FLOOR(1000+RAND()*9000);
		INSERT INTO tmp_sales_order VALUES (@i,@customer_number,@product_code,@order_date,@order_date,@amount);
		SET @i := @i +1;
	END WHILE;
	TRUNCATE TABLE sales_order; -- drop table ：删除表；delete from table:清空表数据，若主键是递增的，后续插入新的记录，会继续递增； truncate  = drop +create

	-- 从临时表中查询所有的记录，然后插入到销售订单表中
	INSERT INTO sales_order
	SELECT NULL,customer_number,product_code,order_date,entry_date,order_amount
	FROM tmp_sales_order;
	COMMIT;
	DROP TABLE tmp_sales_order;
END //