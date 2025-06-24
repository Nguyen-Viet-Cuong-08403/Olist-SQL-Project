-- Bước 1 Cleaning Data 
-- 1.1 Xử lí giá trị Null (Mục tiêu: Phát hiện và xử lý các giá trị NULL trong các cột quan trọng, vì chúng có thể làm sai lệch kết quả phân tích)
    -- Kiểm tra lần lượt từng bảng, đánh giá số lượng null của từng bảng và đưa ra quyết định , dưới đây là một ví dụ để kiểm tra (bảng Order_reviews)
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(review_id) AS null_review_id,
    COUNT(*) - COUNT(order_id) AS null_order_id,
    COUNT(*) - COUNT(review_score) AS null_review_score,
    COUNT(*) - COUNT(review_comment_title) AS null_comment_title,
    COUNT(*) - COUNT(review_comment_message) AS null_comment_message,
    COUNT(*) - COUNT(review_creation_date) AS null_creation_date,
    COUNT(*) - COUNT(review_answer_timestamp) AS null_answer_timestamp
FROM order_reviews;
--1.2 Kiểm tra có trùng lặp hay không 
-- Xác định những cột cần kiểm tra trùng lặp ví dụ đối với bảng Customer thì cột customer_id không nên trùng lặp, hay product_id trong bảng Product
select customer_id, count(*) as count 
from customers
group by customer_id
having count(*) > 1 -- Kết quả trống, từ đó suy ra không có trùng lặp trong bảng Customers, tiến hành kiểm tra lần lượt các cột khác của từng bảng 
-- 1.3.Chuẩn hóa định dạng dữ liệu 
---- 1.3.1. Kiểm tra định dạng hiện tại 
SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Orders' --=> xuất hiện lỗi định dạng thời gian, tiến hành chuyển định dạng nvarchar thành datetime
-- tiến hành thay đổi 
-- Thêm cột tạm cho order_purchase_timestamp
ALTER TABLE orders
ADD order_purchase_timestamp_temp DATETIME;
-- Chuyển dữ liệu từ NVARCHAR sang DATETIME
UPDATE orders
SET order_purchase_timestamp_temp = CONVERT(DATETIME, order_purchase_timestamp, 120)
WHERE ISDATE(order_purchase_timestamp) = 1;
-- Xóa cột cũ
ALTER TABLE orders
DROP COLUMN order_purchase_timestamp;
-- Đổi tên cột tạm thành cột gốc
EXEC sp_rename 'orders.order_purchase_timestamp_temp', 'order_purchase_timestamp', 'COLUMN';
--1.4. Xử lí giá trị ngoại lại bằng phương pháp IQR (hàm bên dưới tìm giá trị Ourlier)
WITH stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) over() AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) over() AS Q3
    FROM order_items
)
SELECT 
    order_id, 
    price
FROM order_items, stats
WHERE price < (Q1 - 1.5 * (Q3 - Q1))
   OR price > (Q3 + 1.5 * (Q3 - Q1)) -- Không thấy giá trị Outlier
--- 2 Khám phá dữ liệu ()
-- Câu 1 Nhóm khách hàng Best Customers có đặc điểm như thế nào? Số lượng? 
-- Để xác nhận nhóm khách hàng Best Customers và phân tích đặc điểm, phương pháp sử dụng là RFM (Recency, Frequency, Monetary) 
-- Tính toán chỉ số R: Recency(Lần mua gần nhất) :Tính toán số ngày kể từ ngày mua hàng gần nhất đó đến một ngày cố định. Giá trị càng nhỏ càng tốt (khách hàng mới mua gần đây).
  --- Tìm thời gian làm mốc 
   Select max(order_purchase_timestamp) as Thời_gian_làm_mốc
   from Orders
--- tìm khoảng cách ngày mua hàng của mỗi khách hàng đến ngày làm mốc
with table_1 as (
select c.customer_id as Mã_Khách_Hàng_R, o.order_purchase_timestamp as Ngày_mua_hàng, 
    (select max(order_purchase_timestamp)
     from orders ) as Ngày_làm_mốc 
from orders as o
join customers as c
on o.customer_id=c.customer_id
), table_2 as (
select *, datediff(day,Ngày_mua_hàng, Ngày_làm_mốc) as Khoảng_cách 
from table_1
), table_3 as (
-- Phân nhóm khách hàng, tiêu chí chia nhóm khách hàng thành 5 nhóm bằng nhau và đánh giá 
select * , NTILE(5) over (order by Khoảng_cách ASC) as Phân_loại_R
from table_2 
), table_4 as (
--- TÍnh chỉ số Frequency: Đếm số lượng đơn hàng duy nhất mà mỗi khách hàng đã đặt
select c.customer_id as Mã_Hàng_Hàng_F, count(distinct order_id) as Số_lương_đơn_hàng
from orders as o
join customers as c
on o.customer_id=c.customer_id
group by c.customer_id
), table_5 as (
select *, ntile(5) over (order by Số_lương_đơn_hàng DESC ) as Phân_loại_F
from table_4
), table_6 as (
--- Tính chỉ số Monetary: Tính tổng giá trị tiền mà mỗi khách hàng đã chi tiêu
select c.customer_id as Mã_Hàng_Hàng_M, oi.price, oi.freight_value, oi.price + oi.freight_value as Tổng_số_tiền
from orders as o
join customers as c
on o.customer_id=c.customer_id
join Order_items as oi
on o.order_id=oi.order_id
), table_7 as (
select *, ntile(5) over(order by Tổng_số_tiền DESC) as Phân_loại_M
from table_6
), table_8 as (
--- Hợp nhất 3 bảng lại với cột Customer_id chung
select table_3.Mã_Khách_Hàng_R, Phân_loại_R as Điểm_số_R , Phân_loại_M as Điểm_số_M, Phân_loại_F as Điểm_số_F
from table_3
join table_5
on table_3.Mã_Khách_Hàng_R=table_5.Mã_Hàng_Hàng_F
join table_7
on table_3.Mã_Khách_Hàng_R=table_7.Mã_Hàng_Hàng_M
), table_9 as (
-- Lọc khách hàng Best Customer : tiêu chí R = 1 ( Mua gần đây), F = 5 (Số đơn nhiều ), M (tiền chi nhiều)
select *
from table_8
where Điểm_số_R = 1 and Điểm_số_M = 5 and Điểm_số_F = 5 
), table_10 as (-- Lấy thông tin khách hàng best customer 
select distinct table_9.Mã_Khách_Hàng_R,c.customer_city, c.customer_state, Order_items.price, Order_items.freight_value, 
Order_payments.payment_type,products.product_category_name
from table_9 
join customers as c
on table_9.Mã_Khách_Hàng_R= c.customer_id
join Orders 
on orders.customer_id=c.customer_id
join Order_items
on orders.order_id=Order_items.order_id
join Order_payments
on Order_payments.order_id=Orders.order_id
join products
on products.product_id=Order_items.product_id
--Sau khi có được danh sách khách hàng best customer và thông tin của họ thì tiến hành mô tả họ bằng những câu hỏi 
--Địa điểm: Thành phố/tiểu bang nào có nhiều "Best Customers" nhất?
--Sản phẩm ưu thích của họ
--Phương thức thanh toán: Họ thường sử dụng loại thanh toán nào?
--Giá trị đơn hàng trung bình (AOV): AOV của riêng nhóm này

2. -- Đâu là khách hàng rời bỏ ? số lượng 
-- Khách hàng rời bỏ được định nghĩa R = 5 (Mua đã lâu), F = 1(Tổng đơn ít) và M = 1 (số tiền chi ít)
with table_1 as (
select c.customer_id as Mã_Khách_Hàng_R, o.order_purchase_timestamp as Ngày_mua_hàng, 
    (select max(order_purchase_timestamp)
     from orders ) as Ngày_làm_mốc 
from orders as o
join customers as c
on o.customer_id=c.customer_id
), table_2 as (
select *, datediff(day,Ngày_mua_hàng, Ngày_làm_mốc) as Khoảng_cách 
from table_1
), table_3 as (
-- Phân nhóm khách hàng, tiêu chí chia nhóm khách hàng thành 5 nhóm bằng nhau và đánh giá 
select * , NTILE(5) over (order by Khoảng_cách ASC) as Phân_loại_R
from table_2 
), table_4 as (
--- TÍnh chỉ số Frequency: Đếm số lượng đơn hàng duy nhất mà mỗi khách hàng đã đặt
select c.customer_id as Mã_Hàng_Hàng_F, count(distinct order_id) as Số_lương_đơn_hàng
from orders as o
join customers as c
on o.customer_id=c.customer_id
group by c.customer_id
), table_5 as (
select *, ntile(5) over (order by Số_lương_đơn_hàng DESC ) as Phân_loại_F
from table_4
), table_6 as (
--- Tính chỉ số Monetary: Tính tổng giá trị tiền mà mỗi khách hàng đã chi tiêu
select c.customer_id as Mã_Hàng_Hàng_M, oi.price, oi.freight_value, oi.price + oi.freight_value as Tổng_số_tiền
from orders as o
join customers as c
on o.customer_id=c.customer_id
join Order_items as oi
on o.order_id=oi.order_id
), table_7 as (
select *, ntile(5) over(order by Tổng_số_tiền DESC) as Phân_loại_M
from table_6
), table_8 as (
--- Hợp nhất 3 bảng lại với cột Customer_id chung
select table_3.Mã_Khách_Hàng_R, Phân_loại_R as Điểm_số_R , Phân_loại_M as Điểm_số_M, Phân_loại_F as Điểm_số_F
from table_3
join table_5
on table_3.Mã_Khách_Hàng_R=table_5.Mã_Hàng_Hàng_F
join table_7
on table_3.Mã_Khách_Hàng_R=table_7.Mã_Hàng_Hàng_M
)
-- Lọc khách hàng Rời Bỏ Customer : tiêu chí R = 5 ( Mua đã lâu ), F = 5 (Số đơn ít ), M (tiền chi ít )
select *
from table_8
where Điểm_số_R = 5 and Điểm_số_M = 1 and Điểm_số_F = 1 
--3.  Nhóm khách hàng có khả năng Churned có đặc điểm như thế nào ? 
-- định nghĩa: R = 5 (đã mua lâu) , F và M  có thể ở mức trung bình hoặc thấp (điểm 1, 2, 3) 
--cho thấy họ không phải là người mua thường xuyên hay chi tiêu lớn gần đây.
with table_1 as (
select c.customer_id as Mã_Khách_Hàng_R, o.order_purchase_timestamp as Ngày_mua_hàng, 
    (select max(order_purchase_timestamp)
     from orders ) as Ngày_làm_mốc 
from orders as o
join customers as c
on o.customer_id=c.customer_id
), table_2 as (
select *, datediff(day,Ngày_mua_hàng, Ngày_làm_mốc) as Khoảng_cách 
from table_1
), table_3 as (
-- Phân nhóm khách hàng, tiêu chí chia nhóm khách hàng thành 5 nhóm bằng nhau và đánh giá 
select * , NTILE(5) over (order by Khoảng_cách ASC) as Phân_loại_R
from table_2 
), table_4 as (
--- TÍnh chỉ số Frequency: Đếm số lượng đơn hàng duy nhất mà mỗi khách hàng đã đặt
select c.customer_id as Mã_Hàng_Hàng_F, count(distinct order_id) as Số_lương_đơn_hàng
from orders as o
join customers as c
on o.customer_id=c.customer_id
group by c.customer_id
), table_5 as (
select *, ntile(5) over (order by Số_lương_đơn_hàng DESC ) as Phân_loại_F
from table_4
), table_6 as (
--- Tính chỉ số Monetary: Tính tổng giá trị tiền mà mỗi khách hàng đã chi tiêu
select c.customer_id as Mã_Hàng_Hàng_M, oi.price, oi.freight_value, oi.price + oi.freight_value as Tổng_số_tiền
from orders as o
join customers as c
on o.customer_id=c.customer_id
join Order_items as oi
on o.order_id=oi.order_id
), table_7 as (
select *, ntile(5) over(order by Tổng_số_tiền DESC) as Phân_loại_M
from table_6
), table_8 as (
--- Hợp nhất 3 bảng lại với cột Customer_id chung
select table_3.Mã_Khách_Hàng_R, Phân_loại_R as Điểm_số_R , Phân_loại_M as Điểm_số_M, Phân_loại_F as Điểm_số_F
from table_3
join table_5
on table_3.Mã_Khách_Hàng_R=table_5.Mã_Hàng_Hàng_F
join table_7
on table_3.Mã_Khách_Hàng_R=table_7.Mã_Hàng_Hàng_M
)
-- Lọc khách hàng 
select *
from table_8
where Điểm_số_R in (5,4) and Điểm_số_M  between 1 and 3 and Điểm_số_F between 1 and 3 

-- 4 Một số câu hỏi Business Quesions để hiểu rõ hơn về nền tảng thương mại và tối ưu hóa các cơ hội phát triển sẵn có
-- 4.1. Tổng doanh thu mà Olist thu được là bao nhiêu và thay đổi như thế nào theo thời gian?
-- Doanh thu theo Ngày 
select format(convert(datetime, orders.order_purchase_timestamp), 'dd - MM - yyyy') as Ngày, sum(Price + freight_value) as Doanh_thu_theo_ngày
from Order_items 
join Orders
on Orders.order_id= Order_items.order_id
group by format(convert(datetime, orders.order_purchase_timestamp), 'dd - MM - yyyy')
order by format(convert(datetime, orders.order_purchase_timestamp), 'dd - MM - yyyy') ASC
-- Doanh thu theo Tháng
select format(convert(datetime, orders.order_purchase_timestamp), 'MM - yyyy') as Tháng, sum(Price + freight_value) as Doanh_thu_theo_ngày
from Order_items 
join Orders
on Orders.order_id= Order_items.order_id
group by format(convert(datetime, orders.order_purchase_timestamp), 'MM - yyyy')
order by format(convert(datetime, orders.order_purchase_timestamp), 'MM - yyyy') ASC
-- Doanh thu theo năm 
select format(convert(datetime, orders.order_purchase_timestamp), 'yyyy') as Tháng, sum(Price + freight_value) as Doanh_thu_theo_ngày
from Order_items 
join Orders
on Orders.order_id= Order_items.order_id
group by format(convert(datetime, orders.order_purchase_timestamp), 'yyyy')
order by format(convert(datetime, orders.order_purchase_timestamp), 'yyyy') ASC
-- 4.2. Có bao nhiêu đơn đặt hàng được đặt trên Olist và số lượng các đơn hàng thay đổi như thế nào theo tháng hoặc mùa?
select format(convert(datetime, orders.order_purchase_timestamp), 'MM - yyyy') as Tháng, count(order_id) as Tổng_đơn_hàng
from Order_items 
group by format(convert(datetime, orders.order_purchase_timestamp), 'MM - yyyy')
order by format(convert(datetime, orders.order_purchase_timestamp), 'MM - yyyy') ASC
-- 4.3. Các danh mục sản phẩm phổ biến nhất trên Olist là gì và doanh số bán hàng của chúng khác nhau như thế nào?
Select p.product_category_name as Danh_mục, count(order_id) as Số_lượng, sum(price+ freight_value) as TỔng_doanh_số
from Order_items as Oi
join Products as p
on Oi.product_id=p.product_id
group by p.product_category_name 
order by count(order_id) DESC
-- 4.4. Giá trị Average Order Value (AOV) trên Olist là bao nhiêu và giá trị này thay đổi như thế nào theo Product Category hoặc Payment Method?
-- Giá trị AVO theo Product Category 
SELECT 
    p.product_category_name AS Danh_mục,
    AVG(subquery.order_total) AS AVO_theo_danh_mục
FROM (
    SELECT 
        oi.order_id,
        SUM(oi.price + oi.freight_value) AS order_total
    FROM Order_items AS oi
    JOIN Products AS p ON oi.product_id = p.product_id
    GROUP BY oi.order_id
) AS subquery
JOIN Products AS p ON subquery.order_id IN (
    SELECT order_id 
    FROM Order_items 
    WHERE product_id = p.product_id
)
GROUP BY p.product_category_name
ORDER BY AVO_theo_danh_mục DESC;
-- Giá trị AVO trên Payment_method 
SELECT 
    pay.payment_type AS Phương_thức,
    AVG(subquery.order_total) AS AVO_theo_phương_thức
FROM (
    SELECT 
        oi.order_id,
        SUM(oi.price + oi.freight_value) AS order_total
    FROM Order_items AS oi
    GROUP BY oi.order_id
) AS subquery
JOIN Order_payments AS pay
    ON subquery.order_id = pay.order_id
GROUP BY pay.payment_type
ORDER BY AVO_theo_phương_thức DESC;