-- Database Creation --
CREATE DATABASE diet_cafe;
USE diet_cafe;

-- Table Creation --
-- Customers Table
CREATE TABLE customers (
    cust_id varchar(5),
    cust_nm varchar(50),
    emp_id varchar(4),
    emp_nm varchar(50),
    dsh_id int,
    dsh_nm varchar(50),
    dsh_prc int,
    odr_id int,
    pmt_status varchar(20),
    pmt_type varchar(20),
    emp_rtgs int,
    dsh_rtgs int,
    service_rtgs int
);

-- Employees Table
CREATE TABLE employees (
    emp_id varchar(4),
    emp_nm varchar(50),
    emp_pos varchar(50),
    emp_sal int,
    cust_id varchar(5),
    tot_odr int,
    tot_sales int,
    emp_rtgs int
);

-- Menu Table
CREATE TABLE menu (
    dsh_id int,
    dsh_nm varchar(50),
    dsh_prc int,
    dsh_rtgs int,
    tot_odr int,
    tot_sales int
);

-- Orders Table
CREATE TABLE orders (
    odr_id int,
    dsh_id int,
    cust_id varchar(5),
    emp_id varchar(4),
    dsh_prc int,
    tot_odr int,
    tot_sales int
);

-- Sales Table
CREATE TABLE sales (
    cust_id varchar(5),
    emp_id varchar(4),
    odr_id int,
    dsh_prc int,
    tot_odr int,
    tot_sales int,
    service_rtgs int
);

-- Ratings Table
CREATE TABLE ratings (
    odr_id int,
    cust_id varchar(5),
    emp_id varchar(4),
    emp_rtgs int,
    dsh_id int,
    dsh_prc int,
    dsh_rtgs int,
    service_rtgs int
);

-- Sample Data Insertion Query --
INSERT INTO customers (cust_id, cust_nm, emp_id, emp_nm, dsh_id, dsh_nm, dsh_prc, odr_id, pmt_status, pmt_type, emp_rtgs, dsh_rtgs, service_rtgs) VALUES
('C1001', 'Rajesh Kumar', 'E001', 'Priya Sharma', 1, 'Quinoa Salad', 320, 10001, 'Paid', 'Credit Card', 4, 5, 4),
('C1002', 'Priya Singh', 'E002', 'Amit Verma', 2, 'Avocado Toast', 280, 10002, 'Pending', 'UPI', 5, 4, 5);

INSERT INTO employees (emp_id, emp_nm, emp_pos, emp_sal, cust_id, tot_odr, tot_sales, emp_rtgs) VALUES
('E001', 'Priya Sharma', 'Manager', 65000, 'C1001', 25, 12500, 4),
('E002', 'Amit Verma', 'Senior Waiter', 45000, 'C1002', 22, 9800, 5);

INSERT INTO menu (dsh_id, dsh_nm, dsh_prc, dsh_rtgs, tot_odr, tot_sales) VALUES
(1, 'Quinoa Salad', 320, 5, 45, 14400),
(2, 'Avocado Toast', 280, 4, 38, 10640);

INSERT INTO orders (odr_id, dsh_id, cust_id, emp_id, dsh_prc, tot_odr, tot_sales) VALUES
(10001, 1, 'C1001', 'E001', 320, 1, 320),
(10002, 2, 'C1002', 'E002', 280, 1, 280);

INSERT INTO sales (cust_id, emp_id, odr_id, dsh_prc, tot_odr, tot_sales, service_rtgs) VALUES
('C1001', 'E001', 10001, 320, 1, 320, 4),
('C1002', 'E002', 10002, 280, 1, 280, 5);

INSERT INTO ratings (odr_id, cust_id, emp_id, emp_rtgs, dsh_id, dsh_prc, dsh_rtgs, service_rtgs) VALUES
(10001, 'C1001', 'E001', 4, 1, 320, 5, 4),
(10002, 'C1002', 'E002', 5, 2, 280, 4, 5);

-- Creating Relation Between Tables --
-- Adding Primary Keys
ALTER TABLE customers ADD PRIMARY KEY (cust_id);
ALTER TABLE employees ADD PRIMARY KEY (emp_id);
ALTER TABLE menu ADD PRIMARY KEY (dsh_id);

-- Adding Foreign Keys for orders table
ALTER TABLE orders ADD FOREIGN KEY (cust_id) REFERENCES customers(cust_id);
ALTER TABLE orders ADD FOREIGN KEY (emp_id) REFERENCES employees(emp_id);
ALTER TABLE orders ADD FOREIGN KEY (dsh_id) REFERENCES menu(dsh_id);

-- Show all tables
SHOW TABLES;

-- Show table structures with keys
SHOW CREATE TABLE customers;
SHOW CREATE TABLE employees;
SHOW CREATE TABLE menu;
SHOW CREATE TABLE orders;
SHOW CREATE TABLE sales;
SHOW CREATE TABLE ratings;

-- Queries Adressing Business Questions --
-- 1. Top 10 Spending Customers
select cust_id, cust_nm, count(*) as total_orders, sum(dsh_prc) as total_spent from customers
group by cust_id, cust_nm
order by total_spent desc
Limit 10;

-- 2. Customer Retention Rate
select
	count(distinct cust_id) as total_customers,
	count(distinct case when tot_odr > 1 then cust_id end) as repeat_customer,
	round((count(distinct case when tot_odr > 1 then cust_id end) / count(distinct cust_id)) * 100, 2) as retention_rate
from customers;

-- 3. Top 10 Best Performing Employees
select e.emp_id, e.emp_nm, e.emp_pos, e.emp_sal, e.tot_odr, e.tot_sales, e.emp_rtgs,
	round(e.tot_sales/e.tot_odr, 2) as avg_order_value
from employees e
order by e.tot_sales desc
limit 10;

-- 4. Top 10 Popular Dishes In Menu
select m.dsh_id, m.dsh_nm, m.dsh_prc, m.tot_odr, m.tot_sales, m.dsh_rtgs
from menu m
order by m.tot_odr desc
limit 10;

-- Average Order values
select
	round(avg(dsh_prc), 2) as avg_order_value,
    min(dsh_prc) as min_order_value,
    max(dsh_prc) as max_order_value
from orders;

-- Service Quality Analysis
select
	round(avg(service_rtgs), 2) as avg_service_rating,
    round(avg(emp_rtgs), 2) as avg_employee_rating,
    round(avg(dsh_rtgs), 2) as avg_dish_rating,
    count(*) as total_ratings
from ratings;

-- Payment Status Analysis
select pmt_status,
	count(*) as order_count,
    sum(dsh_prc) as total_amount
from customers
group by pmt_status;

-- Key Performance Indicators --
select
	(select	count(*) from customers) as total_customers,
    (Select count(*) from orders) as total_orders,
    (select sum(tot_sales) from menu) as total_revenue,
    (select round(avg(tot_sales), 2) from employees) as avg_employee_sales,
    (select round(avg(dsh_prc), 2) from orders) as avg_order_value,
    (select round(avg(emp_rtgs), 2) from ratings) as avg_employee_rating,
    (select round(avg(dsh_rtgs), 2) from ratings) as avg_dish_rating;
    
-- Auto Update Trigger --
delimiter //
create procedure addcompleteorder(
	in input_cust_id varchar(5),
    in input_emp_id varchar(4),
    in input_dsh_id int
)
begin
	declare dish_prc int;
    declare new_odr_id int;
    select dsh_prc into dish_prc from menu where dsh_id = input_dsh_id;
    select coalesce(max(odr_id), 10000) + 1 into new_odr_id from orders;
    insert into orders (odr_id, dsh_id, cust_id, emp_id, dsh_prc, tot_odr, tot_sales)
    values (new_odr_id, input_dsh_id, input_cust_id, input_emp_id, dish_prc, 1, dish_prc);
    select concat('Order', new_odr_id, 'Placed Successfully!') as result;
end//
delimiter ;
-- Usage:- call addcompleteorder('C1101', 'E007', 5);

-- End Of Project --
