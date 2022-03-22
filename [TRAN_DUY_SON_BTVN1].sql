-- 1

Drop database retail;

-- 2

create database retail;

-- 4

alter table orders add merchant_address varchar(100);

alter table orders drop column merchant_address;

--5
create table test_sales
(
sales_id nvarchar(100) primary key,
order_id nvarchar(100),
product_id nvarchar(100),
price_per_unit int,
total_price int,
)