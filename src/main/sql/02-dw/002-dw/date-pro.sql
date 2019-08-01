-- 日期存储过程
DELIMITER //
CREATE PROCEDURE USP_Load_Dim_Date(dt_start DATE,dt_end DATE)
BEGIN

    WHILE dt_start<=dt_end DO
        INSERT INTO dim_date (`date`,`month`,`month_name`,`quarter`,`year`)
        VALUES (dt_start,MONTH(dt_start),MONTHNAME(dt_start),QUARTER(dt_start),YEAR(dt_start));
        SET dt_start =ADDDATE(dt_start,1);
    END WHILE;

COMMIT;
END //

CALL USP_Load_Dim_Date('2010-1-1','2050-1-1');