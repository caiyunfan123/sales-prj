#!/bin/bash

sqoop import \
    --connect jdbc:mysql://master:3306/sales_source \
    --username root \
    --password admin \
    --table product \
    --hive-import \
    --hive-database sales_rds \
    --hive-table product \
    --hive-overwrite \
    --fields-terminated-by '\t'