INSERT overwrite TABLE sales_rds.cdc_time
SELECT ${hiveconf:max_date}, ${hiveconf:pre_date} current_load ;