SELECT * FROM cust_dimen      -- Cust_id unique
---------------------------------------------------
UPDATE market_fact

UPDATE market_fact

UPDATE market_fact

UPDATE market_fact
ALTER TABLE orders_dimen ADD CONSTRAINT PK_2 PRIMARY KEY (Ord_id)
ALTER TABLE prod_dimen ADD CONSTRAINT PK_3 PRIMARY KEY (Prod_id)
ALTER TABLE shipping_dimen ADD CONSTRAINT PK_4 PRIMARY KEY (Ship_id)
ALTER TABLE market_fact ADD CONSTRAINT FK_3 FOREIGN KEY (Prod_id) REFERENCES prod_dimen (Prod_id)
ALTER TABLE market_fact ADD CONSTRAINT FK_4 FOREIGN KEY (Ship_id) REFERENCES shipping_dimen (Ship_id)

SELECT  A.Id, A.Discount, A.Order_Quantity, A.Product_Base_Margin, A.Sales, B.*, C.*,D.*,E.* INTO combined_table

SELECT * FROM combined_table

--//////////////////////////////////
-- 2.Find the top 3 customers who have the maximum count of orders.
select top 3 Cust_id, count(distinct Ord_id) count_of_order from combined_table
group by Cust_id
order by 2 desc

--//////////////////////////////////
-- 3.Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date
ALTER TABLE combined_table ADD DaysTakenForDelivery INT;

SELECT * FROM combined_table

---- alternative solution: ALTER TABLE combined_table ADD  DaysTakenForDelivery1 AS DATEDIFF (DAY,Order_date,Ship_date) PERSISTED

-- NOT: 
/*


select * from combined_table
*/

--//////////////////////////////////
-- 4. Find the customer whose order took the maximum time to get delivered.
SELECT TOP 1 Cust_id, Customer_Name,  Max(DaysTakenForDelivery) Max_delivery_day FROM combined_table
GROUP BY Cust_id, Customer_Name
ORDER BY 3 desc

--//////////////////////////////////
-- 5. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
SELECT MONTH(B.order_date), count(distinct A.Cust_id) Month_ FROM 
(SELECT distinct Cust_id,Customer_Name,Order_Date FROM combined_table where YEAR(Order_Date) = 2011 and MONTH(Order_Date) = 01) A, combined_table B
WHERE A.Cust_id = B.Cust_id AND YEAR(B.Order_Date) = 2011
group by MONTH(B.order_date)
order by 1

-- Alternative Solution
with c1 as(

--//////////////////////////////////
-- 6.Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, in ascending order by Customer ID
CREATE VIEW T1 as (

-- Alternative Solution
WITH K1 AS (

--//////////////////////////////////
-- 7.Write a query that returns customers who purchased both product 11 and product 14, 
-- .. as well as the ratio of these products to the total number of products purchased by the customer.
CREATE VIEW prod_11_14 AS  (
SELECT distinct Cust_id FROM combined_table
WHERE prod_id = '11'
intersect
SELECT distinct Cust_id FROM combined_table
WHERE prod_id = '14')

CREATE VIEW prod_11_sum as (
SELECT Cust_id, Sum(Order_quantity) sum_quantity_11 FROM combined_table WHERE prod_id = '11'
group by Cust_id)

CREATE VIEW prod_14_sum as (
SELECT Cust_id, Sum(Order_quantity) sum_quantity_14 FROM combined_table WHERE prod_id = '14'
group by Cust_id)

CREATE VIEW total_11_14 as (
select A.cust_id, SUM(B.Order_Quantity) total_prod from prod_11_14 A, combined_table B where A.Cust_id = B.Cust_id
group by A.cust_id)

select Distinct A.cust_id, CAST(1.0*B.sum_quantity_11/D.total_prod AS numeric(3,2)),CAST(1.0*C.sum_quantity_14/D.total_prod AS numeric(3,2))
FROM prod_11_14 A, prod_11_sum B,prod_14_sum C ,total_11_14 D
where A.cust_id= B.cust_id AND A.cust_id = C.cust_id AND A.Cust_id =D.Cust_id

-- Alternative Solution
with t1 as(
SELECT distinct Cust_id FROM combined_table
WHERE prod_id = '11'
intersect
SELECT distinct Cust_id FROM combined_table
WHERE prod_id = '14'),
t2 as (SELECT Cust_id, Sum(Order_quantity) sum_quantity_11 FROM combined_table WHERE prod_id = '11'
group by Cust_id),
t3 as (SELECT Cust_id, Sum(Order_quantity) sum_quantity_14 FROM combined_table WHERE prod_id = '14'
group by Cust_id),
t4 as (select A.cust_id, SUM(B.Order_Quantity) total_prod from t1 A, combined_table B where A.Cust_id = B.Cust_id
group by A.cust_id)

select Distinct A.cust_id, CAST(1.0*B.sum_quantity_11/D.total_prod AS numeric(3,2)),CAST(1.0*C.sum_quantity_14/D.total_prod AS numeric(3,2))
FROM t1 A, t2 B,t3 C ,t4 D
where A.cust_id= B.cust_id AND A.cust_id = C.cust_id AND A.Cust_id =D.Cust_id

------------------------------------------------------------------------------------------------------------------------------------------------------
--CUSTOMER SEGMENTATION
--1. Create a view that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)
SELECT Cust_id, YEAR(Order_Date) ord_year, MONTH(Order_Date) ord_month
FROM	combined_table
ORDER BY 1,2,3

--//////////////////////////////////
--2. Create a view that keeps the number of monthly visits by users. (Separately for all months from the business beginning)
CREATE VIEW CNT_CUSTOMER_LOGS AS(
SELECT DISTINCT Cust_id, YEAR(Order_Date) ord_year, MONTH(Order_Date) ord_month, COUNT (*) OVER (PARTITION BY cust_id) CNT_LOG
FROM	combined_table)
-- SELECT * FROM combined_table where Cust_id = 1710

SELECT * FROM CNT_CUSTOMER_LOGS

--//////////////////////////////////
--3. For each visit of customers, create the next month of the visit as a separate column.
CREATE VIEW visits AS 
SELECT *, LEAD(CURRENT_MONTH, 1) OVER (PARTITION BY cust_id ORDER BY CURRENT_MONTH) NEXT_VISIT_MONTH
FROM
(
SELECT *, DENSE_RANK() OVER (ORDER BY ORD_YEAR, ORD_MONTH) CURRENT_MONTH
FROM	CNT_CUSTOMER_LOGS 
) A

SELECT * FROM visits

--/////////////////////////////////
--4. Calculate the monthly time gap between two consecutive visits by each customer.
CREATE VIEW TIME_GAPS AS
SELECT *, NEXT_VISIT_MONTH - CURRENT_MONTH TIME_GAPS
FROM visits

SELECT * FROM TIME_GAPS

--/////////////////////////////////////////
--5.Categorise customers using time gaps. Choose the most fitted labeling model for you.
--  For example: 
--	Labeled as churn if the customer hasn't made another purchase in the months since they made their first purchase.
--	Labeled as regular if the customer has made a purchase every month.
--  Etc.
WITH T1 AS
(
SELECT cust_id, AVG(TIME_GAPS) avg_time_gap
FROM TIME_GAPS
GROUP BY cust_id
) 
SELECT cust_id,
		CASE WHEN avg_time_gap IS NULL THEN 'CHURN'
				WHEN avg_time_gap = 1 THEN 'REGULAR'
				WHEN avg_time_gap > 1 THEN 'IRREGULAR'
				ELSE 'UNKNOWN'
		END AS cust_segment
FROM	T1

----------------------------------------------------------------------------------------------------------------------------------------
--MONTH-WISE RETENTION RATE
--Find month-by-month customer retention rate  since the start of the business.
--1. Find the number of customers retained month-wise. (You can use time gaps)
CREATE VIEW CNT_RETAINED_CUST AS
SELECT *, COUNT(cust_id) OVER (PARTITION BY NEXT_VISIT_MONTH) CNT_RETAINED_CUST
FROM TIME_GAPS
WHERE TIME_GAPS = 1

SELECT * FROM CNT_RETAINED_CUST

CREATE VIEW CNT_TOTAL_CUST AS
SELECT *, COUNT (cust_id) OVER (PARTITION BY CURRENT_MONTH) CNT_TOTAL_CUST
FROM TIME_GAPS
WHERE CURRENT_MONTH > 1

SELECT * FROM CNT_TOTAL_CUST WHERE TIME_GAPS = 1

--//////////////////////
--2. Calculate the month-wise retention rate.
--Basic formula: o	Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Current Month / Total Number of Customers in the Current Month
--It is easier to divide the operations into parts rather than in a single ad-hoc query. It is recommended to use View. 
--You can also use CTE or Subquery if you want.
WITH T1 AS
(
SELECT	DISTINCT A.Cust_id, A.NEXT_VISIT_MONTH, A.CNT_RETAINED_CUST, B.CNT_TOTAL_CUST
FROM	CNT_RETAINED_CUST A, CNT_TOTAL_CUST B
WHERE	B.CURRENT_MONTH = A. NEXT_VISIT_MONTH
AND		B.TIME_GAPS = 1
) 
SELECT DISTINCT NEXT_VISIT_MONTH, CAST (1.0* CNT_RETAINED_CUST/CNT_TOTAL_CUST AS NUMERIC (3,2)) AS  MONTHLY_WISE_RETENTION_RATE
FROM T1
ORDER BY 1