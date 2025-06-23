# Olist Data Analysis Project: Unlocking Customer Insights with SQL
## Project Overview
Dự án này giới thiệu nỗ lực phân tích dữ liệu thực tế bằng cách sử dụng tập dữ liệu thương mại điện tử Olist, một trong những thị trường trực tuyến lớn nhất của Brazil. Tận dụng SQL, tôi đã tiến hành Phân tích dữ liệu thăm dò (EDA) chuyên sâu để phân khúc khách hàng thành các nhóm chính—Khách hàng tốt nhất, Khách hàng đã ngừng sử dụng và Khách hàng tiềm năng đã ngừng sử dụng—bằng cách sử dụng mô hình RFM (Gần đây, Tần suất, Tiền tệ). Ngoài ra, tôi đã giải quyết các câu hỏi kinh doanh quan trọng, bao gồm xu hướng doanh thu, danh mục sản phẩm phổ biến và các biến thể Giá trị đơn hàng trung bình (AOV), cung cấp thông tin chi tiết có thể hành động để tối ưu hóa nền tảng của Olist. ự án này làm nổi bật khả năng làm sạch dữ liệu, thực hiện phân tích nâng cao và cung cấp các giải pháp hướng đến doanh nghiệp của tôi, khiến nó trở thành một minh chứng có giá trị về các kỹ năng Phân tích dữ liệu của tôi kể từ tháng 6 năm 2025.
## Objective
1. Làm sạch và xử lý dữ liệu để đảm bảo độ chính xác và độ tin cậy trong phân tích.
2. Thực hiện phân tích khám phá dữ liệu (EDA) để hiểu hành vi khách hàng và các mô hình giao dịch.
3. Phân nhóm khách hàng thành các nhóm có ý nghĩa (ví dụ: Khách hàng tốt nhất, Khách hàng đã rời bỏ, Khách hàng có nguy cơ rời bỏ) bằng cách sử dụng mô hình RFM (Tái ghé thăm gần đây, Tần suất mua hàng, Giá trị chi tiêu).
4. Phân tích các chỉ số kinh doanh quan trọng như tổng doanh thu, xu hướng số lượng đơn hàng, các danh mục sản phẩm phổ biến và Giá trị Đơn hàng Trung bình (AOV) theo từng phân khúc.
5. Cung cấp các thông tin chuyên sâu có thể hành động để tối ưu hóa nền tảng thương mại điện tử Olist và hỗ trợ việc ra quyết định chiến lược.
## Project Structure
Dự án được xây dựng dựa trên bộ dữ liệu thương mại điện tử Olist, với các mối quan hệ giữa các bảng được minh họa trong sơ đồ thực thể - quan hệ (Entity-Relationship Diagram - ERD) bên dưới
![Project Setup Screenshot](olist_erd.png)

## SQL Code for Table Creation
```sql
-- Create Customers table
CREATE TABLE Customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(5),
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);
-- Create Geolocation table
CREATE TABLE Geolocation (
    geolocation_zip_code_prefix VARCHAR(5),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);
-- Create Order_Items table
CREATE TABLE Order_Items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2)
);
-- Create Order_Payments table
CREATE TABLE Order_Payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10, 2)
);
-- Create Order_Reviews table
CREATE TABLE Order_Reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(200),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);
-- Create Sellers table
CREATE TABLE Sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5),
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);
-- Create Orders table
CREATE TABLE Orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);
-- Create Products table
CREATE TABLE Products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g DECIMAL(10, 2),
    product_length_cm DECIMAL(10, 2),
    product_height_cm DECIMAL(10, 2),
    product_width_cm DECIMAL(10, 2)
);
