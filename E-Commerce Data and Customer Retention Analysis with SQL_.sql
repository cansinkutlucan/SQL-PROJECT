SELECT * FROM cust_dimen      -- Cust_id uniqueSELECT * FROM orders_dimen    -- Ord_id uniqueSELECT * FROM prod_dimen      -- Prod_id uniqueSELECT * FROM shipping_dimen  -- Ship_id unique,SELECT * FROM market_fact
---------------------------------------------------select Product_Base_Margin from market_fact where Product_Base_Margin IS NULL   -- Checking NULL values
UPDATE market_fact   SET Discount = round(0.01*Discount, 2 ),       Product_Base_Margin = round(0.01*Product_Base_Margin, 2)-------------------------------------------------------------------------- cust_dimenSELECT * FROM cust_dimenUPDATE cust_dimen   SET Cust_id = SUBSTRING(Cust_id, PATINDEX('%[0-9]%', Cust_id), LEN(Cust_id))ALTER TABLE cust_dimen ALTER COLUMN Cust_id int not null; -------------------------------------------------------------------------- orders_dimenUPDATE orders_dimen   SET Ord_id = SUBSTRING(Ord_id, PATINDEX('%[0-9]%', Ord_id), LEN(Ord_id))ALTER TABLE orders_dimen ALTER COLUMN Ord_id int not null;-------------------------------------------------------------------------- prod_dimenUPDATE prod_dimen   SET Prod_id = SUBSTRING(Prod_id, PATINDEX('%[0-9]%', Prod_id), LEN(Prod_id))ALTER TABLE prod_dimen ALTER COLUMN Prod_id int not null;-------------------------------------------------------------------------- shipping_dimenUPDATE shipping_dimen   SET Ship_id = SUBSTRING(Ship_id, PATINDEX('%[0-9]%', Ship_id), LEN(Ship_id))ALTER TABLE shipping_dimen ALTER COLUMN Ship_id int not null;ALTER TABLE shipping_dimen ALTER COLUMN Ship_Date date not null;-------------------------------------------------------- Market factUPDATE market_fact   SET Ord_id = SUBSTRING(Ord_id, PATINDEX('%[0-9]%', Ord_id), LEN(Ord_id))

UPDATE market_factSET Prod_id=REPLACE(Prod_id, 'Prod_', '')GO

UPDATE market_fact   SET Ship_id = SUBSTRING(Ship_id, PATINDEX('%[0-9]%', Ship_id), LEN(Ship_id))

UPDATE market_fact   SET Cust_id = SUBSTRING(Cust_id, PATINDEX('%[0-9]%', Cust_id), LEN(Cust_id))UPDATE market_fact    SET Ord_id = CAST(Ord_id as int)ALTER TABLE market_fact ALTER COLUMN Id int not null;ALTER TABLE market_fact ALTER COLUMN Ord_id int not null;ALTER TABLE market_fact ALTER COLUMN Prod_id int not null;ALTER TABLE market_fact ALTER COLUMN Ship_id int not null;ALTER TABLE market_fact ALTER COLUMN Cust_id int not null;------------------------------------------------------ALTER TABLE cust_dimen ADD CONSTRAINT PK_1 PRIMARY KEY (Cust_id)
ALTER TABLE orders_dimen ADD CONSTRAINT PK_2 PRIMARY KEY (Ord_id)
ALTER TABLE prod_dimen ADD CONSTRAINT PK_3 PRIMARY KEY (Prod_id)
ALTER TABLE shipping_dimen ADD CONSTRAINT PK_4 PRIMARY KEY (Ship_id)Alter Table market_fact Add Id int Identity(1,1)ALTER TABLE market_fact ADD CONSTRAINT PK_5 PRIMARY KEY (Id)ALTER TABLE market_fact ADD CONSTRAINT FK_22 FOREIGN KEY (Cust_id) REFERENCES cust_dimen (Cust_id)ALTER TABLE market_fact ADD CONSTRAINT FK_11 FOREIGN KEY (Ord_id) REFERENCES orders_dimen (Ord_id)
ALTER TABLE market_fact ADD CONSTRAINT FK_3 FOREIGN KEY (Prod_id) REFERENCES prod_dimen (Prod_id)
ALTER TABLE market_fact ADD CONSTRAINT FK_4 FOREIGN KEY (Ship_id) REFERENCES shipping_dimen (Ship_id)
select * from cust_dimen------------------------------------------------------------------------------------------------------------------------------------------------------ 1. Using the columns of “market_fact”, “cust_dimen”, “orders_dimen”, “prod_dimen”, “shipping_dimen”, Let's create a new table, named as “combined_table”.
SELECT  A.Id, A.Discount, A.Order_Quantity, A.Product_Base_Margin, A.Sales, B.*, C.*,D.*,E.* INTO combined_table      FROM market_fact A, cust_dimen B, orders_dimen C, prod_dimen D,  shipping_dimen E      WHERE A.Cust_id = B.Cust_id  and A.Ord_id = C.Ord_id 	  and A.Prod_id = D.Prod_id and A.Ship_id = E.Ship_id

SELECT * FROM combined_table

--//////////////////////////////////
-- 2.Find the top 3 customers who have the maximum count of orders.
select top 3 Cust_id, count(distinct Ord_id) count_of_order from combined_table
group by Cust_id
order by 2 desc-- alternative solutionselect Distinct C.Customer_Name,A.count_of_order from(select top 3 Cust_id, count(distinct Ord_id) count_of_order from combined_table group by Cust_id order by 2 desc)A , combined_table Cwhere A.Cust_id=C.Cust_id order by 2 desc

--//////////////////////////////////
-- 3.Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date
ALTER TABLE combined_table ADD DaysTakenForDelivery INT;UPDATE combined_table SET DaysTakenForDelivery = DATEDIFF(DAY, Order_date, Ship_date)

SELECT * FROM combined_table

---- alternative solution: ALTER TABLE combined_table ADD  DaysTakenForDelivery1 AS DATEDIFF (DAY,Order_date,Ship_date) PERSISTED

-- NOT: 
/*ALTER TABLE combined_tableDROP COLUMN DaysTakenForDelivery1;


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
with c1 as(select distinct Cust_id,Customer_Namefrom combined_tablewhere YEAR(Order_Date)=2011 and month(Order_Date)=01)select  DATENAME(MONTH, Order_Date) xc,count(distinct c.Cust_id)from combined_table c,c1where c1.Cust_id=c.Cust_idand YEAR(Order_Date)=2011GROUP BY 	DATENAME(MONTH, Order_Date)ORDER BY 2 desc

--//////////////////////////////////
-- 6.Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, in ascending order by Customer ID
CREATE VIEW T1 as (SELECT * from (SELECT A.Cust_id,A.Customer_Name,A.Ord_id,A.Order_Date, ROW_NUMBER() over(partition by Cust_id order by Order_Date) row_number_ FROM (SELECT distinct Cust_id, Customer_Name, Ord_id, Order_Date FROM combined_table) A) C)CREATE VIEW T2 as (select * from T1 where row_number_ = 3 )CREATE VIEW T4 as (select T1.Cust_id,T1.Order_Date,ROW_NUMBER() over(partition by T1.Cust_id order by T1.Order_Date) row_number_ from T1, T2 where T1.Cust_id = T2.Cust_id )select Cust_id,First_Purchase,Third_Purchase, DATEDIFF(DAY,First_Purchase,Third_Purchase) from (select cust_id,First_Purchase,Third_Purchase, ROW_NUMBER() over(partition by Cust_id order by Third_Purchase) row_number_ from ( select cust_id,LAST_VALUE(T4.order_date) OVER(PARTITION BY Cust_id order by order_date) Third_Purchase,FIRST_VALUE(T4.order_date) OVER(PARTITION BY  Cust_id order by order_date) First_Purchase from T4 WHERE row_number_ IN(1,2,3) ) A ) CWHERE row_number_=3

-- Alternative Solution
WITH K1 AS (SELECT	DISTINCT Cust_id, MIN (Order_Date) OVER (PARTITION BY cust_id) First_order_dateFROM	combined_table), K2 AS(SELECT	DISTINCT Cust_id, Order_date, ord_id,		DENSE_RANK () OVER (PARTITION BY cust_id ORDER BY order_date, ord_id) ord_date_numberFROM	combined_table)SELECT DISTINCT K1.cust_id, First_order_date, Order_Date, ord_date_number, DATEDIFF (DAY, K1.First_order_date,K2.Order_Date) DATE_DIFFFROM K1, K2WHERE K1.Cust_id = K2.Cust_idAND	 K2.ord_date_number = 3

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
