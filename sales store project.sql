create database storesales_data

create table sales_store(
 transaction_id varchar(30),
 customer_id varchar(30),
 customer_name varchar(30),
 customer_age int,
 gender varchar(15),
 product_id varchar(30),
 product_name varchar(30),
 product_category varchar(30),
 quantiy int,
 prce float,
 payment_mode varchar(30),
 purchase_date date,
 time_of_purchase time,
 status varchar(30)
 );

 select * from sales_store

 set dateformat dmy
 bulk insert sales_store
 from 'C:\sales\sales_store_updated_allign_with_video(in).csv'
   with (
       firstrow =2,
       fieldterminator=',',
       rowterminator='\n'
       );

       

       select * from sales_store

       select * into sales from sales_store --here we make copy of our data bec if we do any mistake our original data will be safe

       select * from sales

       --Data Cleaning--

       --step 1 - To check for duplicate

       select transaction_id,count(*)   --here we finding duplicates so we use transaction_id bec its primary key it can't be repeted by help of this we find duplicates
       from sales
       group by transaction_id
       having count(transaction_id) >1

--duplicates
TXN240646
TXN342128
TXN855235
TXN981773

with cte as(     --here we found full details of duplicates
select *,
   ROW_NUMBER() OVER(PARTITION BY transaction_id
   ORDER BY transaction_id) as row_num
   FROM SALES
   )
   select * from cte
   where row_num >1


   --here we checking its only transaction id is duplicate or whole data is duplicate

    with cte as(     
select *,
   ROW_NUMBER() OVER(PARTITION BY transaction_id
   ORDER BY transaction_id) as row_num
   FROM SALES
   )
   select * from cte
   where transaction_id in ('TXN240646','TXN342128','TXN855235','TXN981773')
   -- we check its real duplicates now we delete it 

   --delete duplicates

    with cte as(     
select *,
   ROW_NUMBER() OVER(PARTITION BY transaction_id
   ORDER BY transaction_id) as row_num
   FROM SALES
   )
   delete from cte
   where row_num =2
   select * from cte

   --step 2 - correction of spelling in headers

   exec sp_rename 'sales.quantiy','quantity','column'

   select * from sales

   exec sp_rename 'sales.prce','price','column'

   --step 3 check datatypes

   select column_name,data_type
   from INFORMATION_SCHEMA.columns
   where table_name='sales'

   --step 4  to check null values

   --to check null count for this query get on internet just need to change two things

   declare @sql nvarchar(max) ='', --this is pre query

   select @sql =string_agg  
     'select ''' + column_name + '''as columnname,
     count(*) as nullcount
     from' +quotename (table_schema) + '.your_table --here we have to put table name
     where' +quotename(column_name)+ 'is null',
     ' union all '
)
within group (order by column_name)
from information_schema.columns
where table_name ='your_table'; --and here also table name

--execute the dynamic SQL
exec sp_executesql @sql;

-- query for our table

DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql = STRING_AGG(
    'SELECT ''' + COLUMN_NAME + ''' AS ColumnName,
            COUNT(*) AS NullCount
     FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales
     WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
    ' UNION ALL '
)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales';

EXEC sp_executesql @sql;

--TREATING NULL VALUES

SELECT * from sales
where transaction_id is null
or
customer_id is null
or
customer_name is null
or
customer_age is null
or
gender is null
or
product_id is null
or
product_name is null
or
product_category is null
or
quantity is null
or
payment_mode is null
or
purchase_date is null
or
time_of_purchase is null
or
status is null

delete from sales --because without transaction id what we did
where transaction_id is null


select * from sales
where customer_name='ehsaan ram' --here in one order customer_id is missing so we find this person buy several things and we get his id

update sales
set customer_id='CUST9494'
WHERE transaction_id='TXN977900'


--same like ehsaan ram we found another who customerid is null

select * from sales
where customer_name='damini raju'

update sales
set customer_id='CUST1401'
WHERE transaction_id='TXN985663'

--now we dont have name,age,gender but customerid we have so we check 

select * from sales  --we found details
where customer_id='CUST1003'

update sales
set customer_name='Mahika Saini',customer_age=35,gender='Male'
WHERE transaction_id='TXN432798'

select * from sales 

--Step 5 - Data Cleaning

select distinct gender --Distinct is use to  show only unique values
from sales 

update sales
set gender ='M'
where gender='male'

update sales
set gender ='F'
where gender='female'

select distinct payment_mode
from sales

update sales
set payment_mode='credit card'
where payment_mode='cc'

select * from sales

--DATA ANALYSIS--

--1 What are the top 5 most selling products by quantity ?

select top 5 product_name,sum(quantity) as top_salas  from sales
where status='delivered' --if we not use where then it will show pending,cancelled also
group by product_name 
order by top_salas desc

--Business problem: we don't know which products are most in demand.
--Business Impact : Helps prioritize stock and boost sales through targeted promotions.

--2 Which products are most frequently canceld ?

SELECT TOP 5 PRODUCT_NAME,COUNT(*) AS TOTAL_CANCELED
FROM sales
WHERE STATUS ='CANCELLED'
GROUP BY product_name
ORDER BY TOTAL_CANCELED DESC

--Business Problem:Frequent cancellations affect revenue and customer trust.

--Business Impact:Identify poor-performing product to improve quality or remove from catalog

--3 What time of the day has the highest number of purchases ?

select 
   case 
      when datepart(hour,time_of_purchase) between 0 and 5 then 'night'
      when datepart(hour,time_of_purchase) between 6 and 11 then 'morning'
      when datepart(hour,time_of_purchase) between 12 and 17 then 'afternoon'
      when datepart(hour,time_of_purchase) between 18 and 23 then 'evening'    
      end as time_of_day,
      count(*) as total_order
   from sales
   group by 
      case
          when datepart(hour,time_of_purchase) between 0 and 5 then 'night'
          when datepart(hour,time_of_purchase) between 6 and 11 then 'morning'
          when datepart(hour,time_of_purchase) between 12 and 17 then 'afternoon'
          when datepart(hour,time_of_purchase) between 18 and 23 then 'evening' 
     end
order by total_orders desc

--Business Problem Solved: Find peak sales times

--Business Impact : optimize staffing,promotions and server loads.

--4 Who are the top 5 highest spending customers ?

select * from sales

select top 5 customer_name,
  format(sum(price*quantity),'C0','en-IN') as total_spend  -- ONLY C0 GIVE DOLLAR SYMBOL FOR RUPEES en-IN USE
from sales
group by customer_name
order by sum(price*quantity) desc

--Business Problem Solved: Identify VIP customers.

--Business Impact:Personalized offers,loyalty rewards,and retention.


--5 Which product category generate the highest revenue?

select * from sales

select product_category,
 format(sum(price*quantity),'C0','en-IN') as highest_revenue
from sales
group by product_category
order by sum(price*quantity) desc --here if we right highest_revenue it give wrong  desc so we write direclty formula

--Business Problem Solved:Identify top performing product categories.

--Business Impact:Refine product strategy,supply chain,and promotions.
--allowing the business to invest more in high-margin or high-demand categories.

--6 What is the return/cancellation rate per product category ?

--Cancellation

select product_category,
  format( count(case when status='cancelled' then 1 end)*100.0/count(*),'N3')+' %'as canncelled_product --N3,N use for number and 3 is use after decimal how many numbers show
from sales
group by product_category
order by canncelled_product DESC

--Return

select product_category,
  format( count(case when status='returned' then 1 end)*100.0/count(*),'N3')+' %'as returned_product 
from sales
group by product_category
order by returned_product DESC

--Business Problem Solved : Monitor dissatisfaction trends per category.

--Business Impact : Reduced return,improve product descriptions/expectations.
--Helps identify and fix product or logistics issues.

--7 What is the most preferred payment mode ?

select * from SALES

select payment_mode ,count(payment_mode) as most_use_mode
from sales
group by payment_mode 
order by most_use_mode desc

--Business Problem Solved : know which payment options customer prefer.

--Business Impact: Streamline payment processing,prioritize popular modes.

--8 How does age group affect purchasing behaviour ?

select 
    case  
       when customer_age between 18 and 25 then '18-25'
          when customer_age between 26 and 35 then '26-35' 
             when customer_age between 36 and 50 then '36-50'
             else '51+'
             end as customer_age,
             format(sum(price*quantity),'C0','en-IN') as total_purchase
             from sales
             group by case  
       when customer_age between 18 and 25 then '18-25'
          when customer_age between 26 and 35 then '26-35' 
             when customer_age between 36 and 50 then '36-50'
             else '51+'
             end
             order by sum(price*quantity) desc

--Business Problem Solved : Understand customer demographics.

--Business Impact:Targeted marketing and product recommendations bu age group.

--9 What's the monthly sales trend ?

select 
    year(purchase_date) as years,
    month(purchase_date) as months,
    format(sum(price*quantity),'C0','en-IN') AS total_sales,
    sum(quantity) as total_quantity
  from sales
   group by year(purchase_date),month(purchase_date)
   order by months

--Business Problem Solved:Sales fluctuations go unnoticed.

--Business Impact:Plan inventory and marketing to seasonal trends.

--10 Are certain genders buying specific product categorys ?

 select *
   from (
          select gender,product_category
           from sales
        ) as source_table
pivot (
       count(gender)
       for gender in ([m],[f])
       ) as pivot_table
    order by product_category

--Business Problem Solved:Gender-based product preferences.

--Business Impact: Personalized ads,gender-focused campaigns.


--11 Find top-selling product in each category ?

WITH ranked_products AS (
    SELECT product_category,
           product_name,
           SUM(quantity) AS total_quantity,
           RANK() OVER (
               PARTITION BY product_category
               ORDER BY SUM(quantity) DESC
           ) AS rnk
    FROM sales
    GROUP BY product_category, product_name
)
SELECT *
FROM ranked_products
WHERE rnk = 1

--Business Problem Solved: Identified the top-selling product in each category to understand customer demand and product performance.

--Business Impact: Helped optimize inventory and improve sales strategy by focusing on high-demand products.

--12 Create procedure to get top 5 products by category

CREATE PROCEDURE GetTopProducts
    @category VARCHAR(50)
AS
BEGIN
    SELECT TOP 5
           product_name,
           SUM(quantity) AS total_sales
    FROM sales
    WHERE product_category = @category
    GROUP BY product_name
    ORDER BY total_sales DESC;
END;


-- Example; EXEC GetTopProducts 'Electronics'

--13 Find products with below-average sales quantity ?

SELECT product_name,
       SUM(quantity) AS total_sales
FROM sales
GROUP BY product_name
HAVING SUM(quantity) < (
    SELECT AVG(total_qty)
    FROM (
        SELECT SUM(quantity) AS total_qty
        FROM sales
        GROUP BY product_name
    ) AS avg_sales
)
ORDER BY total_sales

--Business Problem Solved:Identified underperforming products with low sales demand.

--Business Impact:Helps businesses reduce dead inventory and improve profitability through better stock decisions.













 



























        





























    
















































