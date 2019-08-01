-- 存在就删除
drop database if  exists sales_dw cascade;

-- 创建库dw
create database if not exists sales_dw;

use sales_dw;

-- 创建表
create table dim_Product
(
   product_sk           int   ,
   product_code         int ,
   product_name         varchar(128),
   product_category     varchar(256),
   version              varchar(32),
   effective_date       date,
   expiry_date          date
)
clustered by (product_sk ) into 8 buckets
stored as orc tblproperties('transactional'='true'); -- 要更新维度表时，必须设置'transactional'='true'


/*==============================================================*/
/* Table: dim_customer                                          */
/*==============================================================*/
create table dim_customer
(
   customer_sk          int   ,
   customer_number      int ,
   customer_name        varchar(128),
   customer_street_address varchar(256),
   customer_zip_code    int,
   customer_city        varchar(32),
   customer_state       varchar(32),
   version              varchar(32),
   effective_date       date,
   expiry_date          date
)
clustered by (customer_sk ) into 8 buckets
stored as orc tblproperties('transactional'='true');

/*==============================================================*/
/* Table: dim_date                   ``   飘号                                                           */
/*==============================================================*/
create table  dim_date
(
   date_sk              int   ,
   `date`                 date,
   month                tinyint,
   month_name            varchar(16),
   quarter              tinyint,
   year                 int
) row format delimited fields terminated by ','
stored as textfile;

/*==============================================================*/
/* Table: dim_order                                             */
/*==============================================================*/
create table dim_order
(
   order_sk             int  ,
   order_number         int,
   version              varchar(32),
   effective_date       date,
   expiry_date          date
)
clustered by (order_sk ) into 8 buckets
stored as orc tblproperties('transactional'='true');
;

/*==============================================================*/
/* Table: fact_sales_order   ，事实表                                  */
/*==============================================================*/
create table fact_sales_order
(
   order_sk             int  ,
   customer_sk          int  ,
   product_sk           int  ,
   order_date_sk        int  ,
   order_amount         decimal(18,2)
)
partitioned by (order_date string)
clustered by (order_sk) into 1 buckets
row format delimited fields terminated by '\t'
stored as orc tblproperties('transactional'='true');

/*==============================================================*/
/* Table: cdc_time                                             */
/*==============================================================*/
create table sales_rds.cdc_time
(
    last_load       date,
    current_load  date
);