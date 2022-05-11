/* -- Lý Thuyết 
1. SQL viết tắt của cái gì?
Structured Query Language
2. Một câu lệnh SQL để kéo dữ liệu ra khỏi database bắt đầu với lệnh gì?
Select
3. Thứ tự chạy của các lệnh trong một câu SQL kéo dữ liệu ra khỏi database là gì?
FROM
ON
JOIN
WHERE
GROUP BY
WITH CUBE or WITH ROLLUP
HAVING
SELECT
DISTINCT
ORDER BY
TOP
4. Khi muốn cập nhật dữ liệu trong bảng thì dùng lệnh gì?
Update
Set
Where
5. Dùng lệnh gì để xoá dữ liệu khỏi data table trong database?
Delete (dùng được cả với mệnh đề where) và Truncate
6. Để populate dữ liệu (điền dữ liệu) vào một bảng trống thì dùng lệnh gì?
Insert into
7. Sử dụng SQL, viết câu lệnh kéo dữ liệu từ cột FirstName, trong bảng Persons
Select FirstName
from Persons
8. Sử dụng SQL, viết câu lệnh kéo toàn bộ các cột trong bảng Persons
Select * from Persons
9. Mô tả kết quả thu được sau khi thực hiện các loại join sau đây: inner, left, right, full
Inner: chỉ lọc các bản ghi khớp với cả 2 bảng
Left: lấy toàn bộ bản ghi của bảng bên trái và các bản khi phù hợp ở bảng bên phải
Right: lấy toàn bộ bản ghi của bảng bên phải và các bản khi phù hợp ở bảng bên trái
Full: lấy toàn bộ bản ghi ở cả 2 bảng
10.
6 dòng

11.
CRISP_DM gồm các Phase:
- Xác định yêu cầu bài toán
- Hiểu dữ liệu
- Làm sạch và chuẩn hóa dữ liệu
- Thống nhất giải pháp phân tích và thực hiện
- Triển khai và đánh giá
12.
select [1],[2],[3]
from
(select *
from B
where ID in (1,3,4)) as Pivotdata
pivot(
sum(amount)
for ID in ([1],[2],[3])
) as pivottable

*/

-- Phần thực hành
-- Câu 1

--Tạo bảng dữ liệu

create table #users
(
user_id tinyint,
action varchar(50),
dim_date varchar(50)
)
go

insert into #users(user_id, action, dim_date) values (1,'start','1-1-20')
insert into #users (user_id, action, dim_date) values (1,'cancel','1-2-20')
insert into #users (user_id, action, dim_date) values (2,'start','1-3-20')
insert into #users (user_id, action, dim_date) values (2,'publish','1-4-20')
insert into #users (user_id, action, dim_date) values (3,'start','1-5-20')
insert into #users (user_id, action, dim_date) values (3,'cancel','1-6-20')
insert into #users (user_id, action, dim_date) values (4,'start','1-7-20')
go
--Query

select user_id, 1.0 *(publishs/starts) as publish_rate, 1.0*(cancels/starts) as cancel_rate
from
(select user_id,
sum (case when action='start' then 1 else 0 end) as starts,
sum (case when action='publish' then 1 else 0 end) as publishs,
sum (case when action='cancel' then 1 else 0 end) as cancels
from #users
group by user_id) a
order by user_id

-- Câu 2

--Tạo bảng dữ liệu
create table #transactions
(
sender tinyint,
reciver tinyint,
amount int,
transaction_date date
)


insert into  #transactions (sender, reciver, amount, transaction_date) values (5,2,10,Cast('2-12-20' as date))
insert into  #transactions (sender, reciver, amount, transaction_date) values (1,3,15,Cast('2-13-20' as date))
insert into  #transactions (sender, reciver, amount, transaction_date) values (2,1,20,Cast('2-13-20' as date))
insert into  #transactions (sender, reciver, amount, transaction_date) values (2,3,25,Cast('2-14-20' as date))
insert into  #transactions (sender, reciver, amount, transaction_date) values (3,1,20,Cast('2-15-20' as date))
insert into  #transactions (sender, reciver, amount, transaction_date) values (3,2,15,Cast('2-15-20' as date))
insert into  #transactions (sender, reciver, amount, transaction_date) values (1,4,5,Cast('2-16-20' as date))

--Query


;with cte as (select sender as users, -1*sum(amount) as net_change from #transactions  group by sender
union all
select reciver as users, sum(amount) as net_change from #transactions as recived group by reciver)

select users, sum(net_change) as net_change
from cte
group by users
order by net_change desc

-- Cách khác

select
coalesce (sender, reciver) as users,
coalesce (credited, 0) - coalesce (debited,0) as net_change
from
(SELECT 
   sender, 
   SUM(amount) AS debited
FROM #transactions
GROUP BY sender ) as debits
full join
( SELECT 
   reciver, 
   SUM(amount) AS credited
FROM #transactions
GROUP BY reciver ) as credits
on debits.sender = credits.reciver
order by net_change desc


-- Câu 3

create table #items
(
date date,
item varchar(50)
)
go
insert into #items (date, item) values (CAST('01-01-20' AS date),'apple')
insert into #items (date, item) values (CAST('01-01-20' AS date),'apple')
insert into #items (date, item) values (CAST('01-01-20' AS date),'pear')
insert into #items (date, item) values (CAST('01-01-20' AS date),'pear')
insert into #items (date, item) values (CAST('01-02-20' AS date),'pear') 
insert into #items (date, item) values (CAST('01-02-20' AS date),'pear')
insert into #items (date, item) values (CAST('01-02-20' AS date),'pear')
insert into #items (date, item) values (CAST('01-02-20' AS date),'orange')
go

;with cte as (select *,
rank() over (partition by date order by COUNT(item) desc) as rank
from
(select date, item
from #items
) a
group by date, item)

select date, item from cte
where rank = 1
group by date, item, rank

--câu 4

create table #users2
(
user_id tinyint,
action varchar(50),
action_date date)
go

insert into #users2 (user_id, action, action_date) values (1, 'start', CAST('2-12-20' AS date))
insert into #users2 (user_id, action, action_date) values (1, 'cancel', CAST('2-13-20' AS date))
insert into #users2 (user_id, action, action_date) values (2, 'start', CAST('2-11-20' AS date))
insert into #users2 (user_id, action, action_date) values (2, 'publish', CAST('2-14-20' AS date))
insert into #users2 (user_id, action, action_date) values (3, 'start', CAST('2-15-20' AS date))
insert into #users2 (user_id, action, action_date) values (3, 'cancel', CAST('2-15-20' AS date))
insert into #users2 (user_id, action, action_date) values (4, 'start', CAST('2-18-20' AS date))
insert into #users2 (user_id, action, action_date) values (1, 'publish', CAST('2-19-20' AS date))
go

;with cte_epalsed as (select user_id, action, action_date, row_number() over(partition by user_id order by action_date desc) as rank
from #users2)

select a.user_id, DATEDIFF("D",b.action_date,a.action_date) as days_elapsed
from
(select user_id, action, action_date from cte_epalsed
where rank = 1) as a
full join
(select user_id, action, action_date from cte_epalsed
where rank = 2) as b
on a.user_id = b.user_id

--câu 6
create table #mobile (user_id tinyint, page_url varchar(10))

create table #web (user_id tinyint, page_url varchar(10))

insert into #mobile values (1, 'A'), (2, 'B'), (3, 'C'), (4, 'A'), (9, 'B'), (2, 'C'), (10, 'B')

insert into  #web values (6, 'A'), (2, 'B'), (3, 'C'), (7, 'A'), (4, 'B'), (8, 'C'), (5, 'B')


--dùng dynamic SQL
create table #fraction (mobile_fraction float, web_fraction float, both_fraction float)

declare @user_both float;
select @user_both = count(distinct #mobile.user_id)
from #mobile inner join #web on #mobile.user_id = #web.user_id

declare @mobile_user float;
select @mobile_user = count(distinct #mobile.user_id) - @user_both
from #mobile

declare @web_user float;
select @web_user = count(distinct #web.user_id) - @user_both
from #web

declare @mobile_fraction float;
set @mobile_fraction = @mobile_user*1.0 / (@mobile_user*1.0 + @user_both*1.0 + @web_user*1.0)

declare @web_fraction float;
set @web_fraction = @web_user / (@mobile_user*1.0 + @user_both*1.0 + @web_user*1.0)

declare @both_fraction float;
set @both_fraction = @user_both / (@mobile_user*1.0 + @user_both*1.0 + @web_user*1.0)

insert into #fraction values (@mobile_fraction, @web_fraction, @both_fraction)

select * from #fraction

--- cách khác
;with full_user as (select distinct w.user_id as web_user, m.user_id as mobile_user
 from #web w full join #mobile m on w.user_id = m.user_id)

 select
 avg(case when mobile_user is not null and web_user is null then 1.0 else 0 end) as mobile_fraction,
 avg(case when web_user is not null and mobile_user is null then 1.0 else 0 end) as web_fraction,
 avg(case when mobile_user is not null and web_user is not null then 1.0 else 0 end) as both_fraction
 from full_user

 -- Câu 7

 create table #projecks (task_id tinyint, start_date date, end_date date)

 insert into #projecks values
(1, CAST('10-01-20' AS date), CAST('10-02-20' AS date)),
(2, CAST('10-02-20' AS date), CAST('10-03-20' AS date)), 
(3, CAST('10-03-20' AS date), CAST('10-04-20' AS date)), 
(4, CAST('10-13-20' AS date), CAST('10-14-20' AS date)), 
(5, CAST('10-14-20' AS date), CAST('10-15-20' AS date)), 
(6, CAST('10-28-20' AS date), CAST('10-29-20' AS date)), 
(7, CAST('10-30-20' AS date), CAST('10-31-20' AS date))

with 

start_date_cte as (
select start_date 
from #projecks
where start_date not in (select end_date from #projecks)),

end_date_cte as (
select end_date 
from #projecks
where end_date not in (select start_date from #projecks)),

projecks_cte as (SELECT 
   start_date, MIN(end_date) AS end_date
FROM start_date_cte, end_date_cte
WHERE start_date < end_date
group by start_date)

select *, DATEDIFF("D",start_date,end_date) as projeck_duration
from projecks_cte
order by start_date

--Câu 8

create table #users8 (user_id tinyint, name varchar(20), join_date date)

insert into #users8 values 
(1, 'Jon', CAST('2-14-20' AS date)), 
(2, 'Jane', CAST('2-14-20' AS date)), 
(3, 'Jill', CAST('2-15-20' AS date)), 
(4, 'Josh', CAST('2-15-20' AS date)), 
(5, 'Jean', CAST('2-16-20' AS date)), 
(6, 'Justin', CAST('2-17-20' AS date)),
(7, 'Jeremy', CAST('2-18-20' AS date))


create table #events (user_id tinyint, type varchar(20), access_date date)

insert into #events values
(1, 'F1', CAST('3-1-20' AS date)), 
(2, 'F2', CAST('3-2-20' AS date)), 
(2, 'P', CAST('3-12-20' AS date)),
(3, 'F2', CAST('3-15-20' AS date)), 
(4, 'F2', CAST('3-15-20' AS date)), 
(1, 'P', CAST('3-16-20' AS date)), 
(3, 'P', CAST('3-22-20' AS date))


-- Query
with
F2_cte as (
	select user_id
	from #events
	where type = 'F2'),

P_cte as (
	select user_id, access_date
	from #events
	where type = 'P'),

P_and_F2 as (
	select P_cte.user_id, P_cte.access_date
	from F2_cte, P_cte
	where F2_cte.user_id = P_cte.user_id),

Upgrade_amount as (
	select COUNT(pnf.user_id) as Upgrade_amount
	from P_and_F2 pnf inner join #users8 on pnf.user_id = #users8.user_id
	where DATEDIFF("D",#users8.join_date,pnf.access_date) <= 30)

select round((cast(Upgrade_amount as float)/cast(COUNT(#users8.user_id) as float)),2) as upgrade_rate
from Upgrade_amount, #users8 
group by Upgrade_amount

--Cau 9
create table #scores (id tinyint, scores float)
insert into #scores values 
(1, 3.50),
(2, 3.65),
(3, 4.00),
(4, 3.85),
(5, 4.00),
(6, 3.65)

select s1.scores, COUNT (distinct s2.scores) as score_rank
from #scores s1, #scores s2 
where s1.scores <= s2.scores
group by s1.id, s1.scores
order by s1.scores desc

--Câu 10
create table #orders10 (order_id tinyint, customer_id tinyint, product_id tinyint)
insert into #orders10 values
(1, 1, 1),
(1, 1, 2),
(1, 1, 3),
(2, 2, 1),
(2, 2, 2),
(2, 2, 4),
(3, 1, 5)

create table #products (id tinyint, name varchar(20))
insert into #products values
(1, 'A'),
(2, 'B'),
(3, 'C'),
(4, 'D'),
(5, 'E')

with 

order_cte as (
select o1.product_id as prod_1, o2.product_id as prod_2
from #orders10 o1, #orders10 o2
where o1.order_id = o2.order_id and o1.product_id < o2.product_id),

product_pair_cte as (select CONCAT(p1.name, ' ', p2.name) as product_pair
from order_cte o inner join #products p1
on o.prod_1 = p1.id
inner join #products p2 on o.prod_2 = p2.id)

select top 3 *, COUNT(product_pair) as  purchase_freg
from product_pair_cte
group by product_pair
order by purchase_freg desc

