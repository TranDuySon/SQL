--Cau 1
--1. Hàm xác định thứ trong tuần

create function thu_trong_tuan(@ngay date)
returns int 
as
begin
	declare @KQ int = Datepart(Weekday, @ngay)
	return @KQ 
end



--2. Hàm xác định tuổi khách hàng tại ngày đăng ký

create function tuoiKH(@ngaysinh date, @ngayDK date)
returns int
as
begin
	declare @KQ int = datediff(YEAR, @ngaysinh, @ngayDK)
	return @KQ
end


--3 Sử dụng  hàm  viết  ra  trong  câu  1,  2,  viết  query  hiển  thị MAKH,  TUOI  (tại  tk  đăng  ký), BIRTH_WEEKDAY (Sinh vào thứ mấy trong tuần)
select MAKH, DBO.tuoiKH(NGSINH, NGDK) as TUOI, dbo.thu_trong_tuan(NGSINH) as BIRTHDAY_WEEK
from KHACHHANG

--Câu 2: Table function
--1.Tìm thông tin khách hàng mua nhiều sp nhất tại ngày dd/mm/yyyy (biến đầu vào)Table: [CTHD],[HOADON],[KHACHHANG]
alter function best_customer(@ngay Date)
returns table
as return
(
select top 1 kh.MAKH, kh.HOTEN, FORMAT(hd.NGHD,'dd/MM/yyyy') as NGAY, SUM(ct.SL) as san_pham_mua
from CTHD ct inner join HOADON hd on ct.SOHD = hd.SOHD
inner join KHACHHANG kh on hd.MAKH = kh.MAKH
where FORMAT(hd.NGHD,'dd/MM/yyyy') = Format(@ngay,'dd/MM/yyyy')
group by kh.MAKH, kh.HOTEN, FORMAT(hd.NGHD,'dd/MM/yyyy')
order by san_pham_mua desc
)

--2.Tìm số lượng sp theo từng hợp đồng. Trong trường hợp: Biến đầu vào = 0 thì hiển thị SLSP theo từng HĐ. Biến đầu vào = @SOHD thì hiển SLSP của @SOHDTable: [CTHD]
create function SP_theo_HD(@sohd int)
returns @bien_bang table
(
SOHD int,
SL int
)
as
begin
if @sohd = 0
	begin
	insert into @bien_bang
	select SOHD, SUM(CTHD.SL) as SL
	from CTHD
	group by SOHD
	return
	end
else
	begin
	insert into @bien_bang
	select SOHD, SUM(CTHD.SL) as SL
	from CTHD
	where SOHD = @sohd
	group by SOHD
	return
	end
return
end

--3. IF...ELSE1.
--Nếu SL không có giá trị NULL va SL >= 100 thì in ra màn hình ‘[SOHD]có [SL]sản phẩm’
--Nếu SL không có giá trị NULL và SL < 100 thì in ra màn hình ‘SOHD có SLSP không đạt’
--Nếu SL có giá trị NULL thì in ra màn hình ‘SLSP chưa được ghi nhận’
select * from CTHD
select sum(SL) from CTHD where SOHD = 1001
alter procedure IF_ELSE(@sohd int)
as
begin
declare @sl int = (select sum(SL) from CTHD where SOHD = @sohd)
if @sl is null
print N'SLSP chưa được ghi nhận'
	
if @sl < 100
	print cast(@sohd as char) + N'có SLSP không đạt'
else
	print cast(@sohd as char) + N'có ' + cast(@sl as char) + N'sản phẩm'
end

--Câu 4. Case when
--1.Đánh dấu khách hàng mới cũ theo từng năm
alter procedure IsExisting
as
begin
	with cte as (select hd.MAKH, FORMAT(hd.NGHD,'yyyy') as NAM_HD,
	ROW_NUMBER() over(partition by hd.MAKH order by FORMAT(hd.NGHD,'yyyy') ) as rn -- đánh số lần xuất hiện của mỗi MAKH theo thời gian
	from HOADON hd
	group by hd.MAKH, FORMAT(hd.NGHD,'yyyy')
	)

	select MAKH, NAM_HD,
	case when rn = 1 then 'New' else 'Existing' end as flag
	from cte
	order by MAKH, NAM_HD
end

exec IsExisting

--2. Điền trị giá cho HĐ có mã 1200, 1300, 1400, 2000lần lượt là 1.200.000, 1.300.000, 1.400.000 và 1.500.000-Using CASE in an UPDATE statement
SELECT * INTO HOADON_2 FROM HOADON
update HOADON_2
set	TRIGIA = case
	when SOHD = 1200 then 1200000
	when SOHD = 1300 then 1300000
	when SOHD = 1400 then 1400000
	when SOHD = 2000 then 1500000
end

--Cau 5
alter procedure BAO_CAO
as
begin
	declare @BIEN_BANG table -- tạo biến bảng để đổ kết quả cuối cùng
	(
	MONTH nvarchar(max),
	REVENUE int,
	TENSP nvarchar(max),
	SLSP int,
	SP_DOANHSO int,
	MAKH char(10),
	TENKH nvarchar(max),
	TUOI int,
	MANV char(10),
	TENNV nvarchar(max)
	)
	declare @THANG table --tạo biến lưu trữ các tháng
	(
	THANG_Id int,
	MONTH nvarchar(max))
	insert into @THANG -- đổ danh sách các tháng trong Database vào biến @THANG
	select
	ROW_NUMBER() over(order by FORMAT(HOADON.NGHD,'MM-yyyy')desc) as THANG_Id,
	FORMAT(HOADON.NGHD,'MM-yyyy') as MONTH
	from HOADON
	group by FORMAT(HOADON.NGHD,'MM-yyyy')

	declare 
	@FromMonth int = 1, --Biến chạy tuần tự các tháng, bắt đầu từ tháng 1
	@ToMonth int = (select max(THANG_id) from @THANG), -- Tháng cuối cùng trong database
	@Month nvarchar(max)

	while @FromMonth <= @ToMonth --Vòng lặp chạy lần lượt từ tháng 1 tới tháng cuối cùng
	begin

	set @Month = (select MONTH from @THANG where THANG_Id = @FromMonth)	 --biến @FromMonth chạy đến tháng nào thì lấy định dạng MONTH của tháng đó trong bảng @THANG gán vào biến @Month

		select FORMAT(HOADON.NGHD,'MM-yyyy') as THANG, SUM(HOADON.TRIGIA) as REVENUE -- Tính doanh thu theo tháng
		into #TEMP1 --đổ kết quả query vào bảng tạm #TEMP1
		from HOADON
		where FORMAT(HOADON.NGHD,'MM-yyyy') = @Month
		group by FORMAT(HOADON.NGHD,'MM-yyyy')
--Lấy SP
		select top 1 SANPHAM.TENSP as TENSP, SUM(CTHD.SL) as SLSP, SUM(CTHD.SL*SANPHAM.GIA) as SP_DOANHSO --
		into #TEMP2 --đổ kết quả query vào bảng tạm #TEMP2
		from CTHD inner join HOADON on CTHD.SOHD = HOADON.SOHD
		inner join SANPHAM on CTHD.MASP = SANPHAM.MASP
		where FORMAT(HOADON.NGHD,'MM-yyyy') = @Month
		group by SANPHAM.TENSP
		order by SUM(CTHD.SL) desc

	--insert into @BIEN_BANG (MAKH,TENKH,TUOI) --KH
		select top 1 kh.MAKH as MAKH, kh.HOTEN as TENKH, DBO.tuoiKH(kh.NGSINH,hd.NGHD) as TUOI
		into #TEMP3 --đổ kết quả query vào bảng tạm #TEMP3
		from CTHD ct inner join HOADON hd on ct.SOHD = hd.SOHD
		inner join KHACHHANG kh on hd.MAKH = kh.MAKH
		where FORMAT(hd.NGHD,'MM-yyyy') = @Month
		group by kh.MAKH, kh.HOTEN, DBO.tuoiKH(kh.NGSINH,hd.NGHD)
		order by SUM(hd.TRIGIA) desc

	--insert into @BIEN_BANG (MANV,TENNV)--NV
		select top 1  nv.MANV as MANV,  nv.HOTEN as TENNV
		into #TEMP4 --đổ kết quả query vào bảng tạm #TEMP4
		from
		HOADON hd left join NHANVIEN nv on hd.MANV = nv.MANV
		where FORMAT(hd.NGHD,'MM-yyyy') = @Month
		group by nv.MANV, nv.HOTEN
		order by SUM(hd.TRIGIA) desc
	
		insert into @BIEN_BANG
		select * from  #TEMP1, #TEMP2, #TEMP3, #TEMP4 -- đưa dữ liệu trong các bảng tạp vào @BIEN_BANG để thành báo cáo chung

		set @FromMonth = @FromMonth + 1 -- biến @FromMonth chuyển sang tháng kế tiếp
		drop table #TEMP1, #TEMP2, #TEMP3, #TEMP4 --reset các bảng tạm trước khi kết thúc một vòng
		continue;
	end
	select * from @BIEN_BANG
end

exec BAO_CAO