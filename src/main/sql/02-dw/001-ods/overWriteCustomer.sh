#!/bin/bash

sqoop import \
    --connect jdbc:mysql://master:3306/sales_source \
    --username root \
    --password admin \
    --table customer \
    --hive-import \
    --hive-database sales_rds \
    --hive-table customerZ \
    --hive-overwrite \
    --fields-terminated-by '\t'