----------Monday Coffee -- Data Analysis-------------

select * from city;
select * from products;
select * from customers;
select * from sales;

--- Reports & Data Analysis---

-- Q.1 **Coffee Consumers Count**  
--    How many people in each city are estimated to consume coffee, given that 25% of the population does?

select city_name,
       round(
	   (population * 0.25)/1000000,
	   2) as coffee_consumers_in_millions,
	   city_rank
from city order by population desc

-- Q.2 **Total Revenue from Coffee Sales**  
--    What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select  ct.city_name, sum (s.total) as total_revenue
from sales s join customers c on s.customer_id = c.customer_id

join city ct on ct.city_id = c.city_id

where extract(quarter from s.sale_date)=4 and extract(year from s.sale_date)=2023
group by ct.city_name
order by 2 desc

-- Q.3 **Sales Count for Each Product**  
--    How many units of each coffee product have been sold?
 
select  p.product_name, count(s.sale_id) as total_orders
 from  products p left join sales s on s.product_id = p.product_id
group by 1
order by 2 desc

-- Q.4 **Average Sales Amount per City**  
--    What is the average sales amount per customer in each city?


select  ct.city_name, sum (s.total) as total_revenue,

count( distinct s.customer_id) as total_customers,

sum (s.total)/count( distinct s.customer_id) as avg_sale_per_city

from sales s join customers c on s.customer_id = c.customer_id

join city ct on ct.city_id = c.city_id


group by ct.city_name
order by 2 desc

-- Q.5 **City Population and Coffee Consumers**  
--    Provide a list of cities along with their populations (25%) and estimated coffee consumers.

with city_table as 

(select city_name ,
round ((population * 0.25)/1000000,2) as coffee_customers 
from city), 
customer_table
as
(select ci.city_name,
count(distinct c.customer_id)as unique_customer
from sales s join customers c on c.customer_id = s.customer_id
join city ci on ci.city_id = c.city_id 
group by 1)

select customer_table.city_name ,
       city_table.coffee_customers,
         customer_table.unique_customer
from city_table
join
customer_table on city_table.city_name = customer_table.city_name

-- Q.6 **Top Selling Products by City**  
--    What are the top 3 selling products in each city based on sales volume?


select * from 

(select ct.city_name,
product_name,
count (s.sale_id) as total_orders,
dense_rank () over(partition by ct.city_name order by count (s.sale_id) desc ) as Rankings
from sales s join products p on p.product_id = s.product_id
join customers c on c.customer_id = s.customer_id
join city ct on ct.city_id = c.city_id
group by 1,2
order by 1,3 desc) where Rankings<=3

-- Q.7 **Customer Segmentation by City**  
--    How many unique customers are there in each city who have purchased coffee products?


select ct.city_name,
      count(distinct c.customer_id) as unique_customers
from city ct left join customers c on ct.city_id = c .city_id
join sales s on s.customer_id=c.customer_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by ct.city_name

-- Q.8 **Average Sale vs Rent**  
--    Find each city and their average sale per customer and avg rent per customer

with city_table as

(select  ct.city_name,

count( distinct s.customer_id) as total_customers,

sum (s.total)/count( distinct s.customer_id) as avg_sale_per_city

from sales s join customers c on s.customer_id = c.customer_id

join city ct on ct.city_id = c.city_id


group by ct.city_name
order by 2 desc),
city_rent
as
(select city_name,
       estimated_rent
	   from city)
	   
select city_rent.city_name,
      city_rent.estimated_rent,
	  city_table.total_customers,
	  city_table.avg_sale_per_city,
      round  (estimated_rent::numeric/city_table.total_customers::numeric,2) as avg_rent_per_customer
from city_table 
join 
city_rent on city_table.city_name=city_rent.city_name
order by 5 desc


-- Q.9 **Monthly Sales Growth**  
--    Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city .

with city_year as 

(select  
ct.city_name,
extract(month from sale_date) as month,
extract (year from sale_date) as year,
sum(total) as total_sales from
sales s join customers c on s.customer_id = c.customer_id
join city ct on ct.city_id = c.city_id
group by 1,2,3
order by 1,3,2),

growth_ratio as

(select city_name,
       month,
	  year,
       total_sales as monthly_sales,
	   lag(total_sales,1) over(partition by city_name order by year,month) as last_month_sale
	   from city_year)
	   
select city_name,
       month,
	   year,
	   monthly_sales,
	   last_month_sale,
	  round ((monthly_sales-last_month_sale)::numeric/last_month_sale::numeric*100,2) as growth_ratio
	  from growth_ratio
	  where growth_ratio is not null
	   
-- Q.10 **Market Potential Analysis**  
--     Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated  coffee consumer
    	   
with city_table as

(select  ct.city_name,sum (s.total) as total_revenue,


count( distinct s.customer_id) as total_customers,

sum (s.total)/count( distinct s.customer_id) as avg_sale_per_city

from sales s join customers c on s.customer_id = c.customer_id

join city ct on ct.city_id = c.city_id


group by ct.city_name
order by 2 desc),

city_rent
as
(select city_name,
       estimated_rent,
	  round(population * 0.25/1000000,2) as est_coffee_consumer_in_million
	   from city)
	   
select city_rent.city_name,
       city_table.total_revenue,
      city_rent.estimated_rent as total_rent,
	  city_table.total_customers,
	  est_coffee_consumer_in_million,
	  city_table.avg_sale_per_city,
      round  (estimated_rent::numeric/city_table.total_customers::numeric,2) as avg_rent_per_customer
from city_table 
join 
city_rent on city_table.city_name=city_rent.city_name
order by 2 desc

	   
------Recomendation--------

-- city 1 : Pune
-- 1.Average rent per customer is less
-- 2.high total revenue
-- 3.avg sale per customer is high

-- city 2: Delhi
-- 1. highest estimated coffee consumer i.e 7.7M
-- 2. Higest total customers which is 68 
-- 3. Avg rent per customer 330 (still under 500)

-- city 3; Jaipur
-- 1.highest no. of customers  which is 69
-- 2. avg rent per customer is very less i.e 156
-- 3. averge sale per customer is better i.e 11.6k







