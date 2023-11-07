-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region
select DISTINCT market 
from dim_customer 
where customer = 'Atliq Exclusive' and region = 'APAC';
 /* ouput 
 MARKET
 South Korea
Philiphines
Newzealand
Japan
Indonesia
India
Bangladesh
Australia*/

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
-- --- unique_products_2020
-- --- unique_products_2021
-- --- percentage_chg
WITH CTE AS (SELECT 
(SELECT COUNT(DISTINCT PRODUCT_CODE) FROM fact_gross_price WHERE FISCAL_YEAR = 2020) AS unique_products_2020,
(SELECT COUNT(DISTINCT PRODUCT_CODE) FROM fact_gross_price WHERE FISCAL_YEAR = 2021) AS unique_products_2021
)
SELECT unique_products_2020, unique_products_2021,
	ROUND((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) AS percentage_chg
FROM CTE;

/* output
unique_products_2020 - 245
unique_products_2021 - 334
percentage_chg - 36.33

*/

-- 3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, segment product_count

select segment, count(distinct product) as product_count
from dim_product
group by segment
order by product_count desc;

/* OUTPUT

	segment	product_count
	Accessories	20
	Peripherals	20
	Notebook	17
	Storage	9
	Desktop	4
	Networking	3
*/
-- 4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment product_count_2020 product_count_2021 difference
with 2020_cnt as ( select segment, count(distinct product) product_count_2020 
from dim_product p
join fact_gross_price gp on p.product_code=gp.product_code
where fiscal_year = 2020
group by segment),
2021_cnt as ( select segment, count(distinct product) product_count_2021
from dim_product p
join fact_gross_price gp on p.product_code=gp.product_code
where fiscal_year = 2021
group by segment)
select 2020_cnt.segment, product_count_2020, product_count_2021, (product_count_2021-product_count_2020) as difference
from 2020_cnt
join 2021_cnt on 2020_cnt.segment=2021_cnt.segment
order by difference desc
limit 1;

/* output
	segment product_count_2020 product_count_2021 difference

	Accessories	13	19	6
	Peripherals	15	20	5
	Desktop	1	3	2
	Notebook	14	16	2
	Networking	2	3	1
	Storage	6	7	1
*/

-- 5. Get the products that have the highest and lowest manufacturing costs.The final output should contain these fields, product_code, product, manufacturing_cost
  select p.product_code, product, manufacturing_cost
 from dim_product p 
 join fact_manufacturing_cost m 
	on p.product_code=m.product_code
where manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost) or
	 manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost);
/* OUPUT
product_code, product, manufacturing_cost
A6120110206	AQ HOME Allin1 Gen 2	240.5364
A2118150101	AQ Master wired x1 Ms	0.8920
*/

-- 6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields, customer_code customer average_discount_percentage
select  c.customer_code, c.customer, avg(pre_invoice_discount_pct) as average_discount_percentage
from dim_customer c
join fact_pre_invoice_deductions pre
	using(customer_code)
where c.market='India' and fiscal_year = 2021
group by c.customer_code, c.customer
order by average_discount_percentage desc 
limit 5;

/* Output 
	customer_code customer average_discount_percentage
	90002009   Flipkart 0.30830000
	90002006	Viveks	0.30380000
	90002003	Ezone	0.30280000
	90002002	Croma	0.30250000
	90002016	Amazon 	0.29330000
*/


-- 7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: Month Year Gross sales Amount

select month(date) as month, s.fiscal_year, sum(sold_quantity*gross_price) as gross_sales_amt
from fact_sales_monthly s 
join dim_customer c on s.customer_code=c.customer_code
join fact_gross_price gp on s.product_code=gp.product_code and  s.fiscal_year=gp.fiscal_year
where customer='Atliq Exclusive'
group by month, s.fiscal_year
order by month, s.fiscal_year  ;

/* output
1	2020	4740600.1605
1	2021	12399392.9788
2	2020	3996227.7661
2	2021	10129735.5675
3	2020	378770.9700
3	2021	12144061.2501
4	2020	395035.3535
4	2021	7311999.9547
5	2020	783813.4238
5	2021	12150225.0139
6	2020	1695216.6008
6	2021	9824521.0110
7	2020	2551159.1584
7	2021	12092346.3245
8	2020	2786648.2601
8	2021	7178707.5902
9	2020	4496259.6724
9	2021	12353509.7938
10	2020	5135902.3467
10	2021	13218636.1966
11	2020	7522892.5608
11	2021	20464999.0997
12	2020	4830404.7285
12	2021	12944659.6509*/

-- 8.In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity

select  
		case when month(date) in (9,10,11) then 'Q1'
			when month(date) in(12,1,2) then 'Q2'
            when month(date) in(3,4, 5) then 'Q3'
            else 'Q4' end as quarter,
           sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year=2020
group by quarter
order by total_sold_quantity desc;

/* output
	Quarter total_sold_quantity	
	Q1	7005619
	Q2	6649642
	Q4	5042541
	Q3	2075087
*/

-- 9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel gross_sales_mln percentage


with 2021_gross_sales as (
	select (sum(sold_quantity*gross_price)) as total_gs_mln 
    from fact_sales_monthly s1
    join fact_gross_price gp on s1.product_code=gp.product_code and s1.fiscal_year=gp.fiscal_year
    where s1.fiscal_year=2021
)
select channel, round((sum(sold_quantity*gross_price)/1000000),2)  gross_sales_mln, round(sum((sold_quantity*gross_price)*100)/total_gs_mln, 1) as gross_sales_mln_pct
from fact_sales_monthly s
join dim_customer c on s.customer_code=c.customer_code
join fact_gross_price gp on s.product_code=gp.product_code and s.fiscal_year=gp.fiscal_year
join 2021_gross_sales gs on 1 = 1
where s.fiscal_year=2021
group by channel,total_gs_mln;

/* Ouput
	channel gross_sales_mln gross_sales_mln_pct
	Direct	257.53	15
	Retailer	1219.08	73
	Distributor	188.03	11

*/

-- 10.	Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division product_code codebasics.io product total_sold_quantity rank_order

with cte as(select division, s.product_code, product, sum(sold_quantity) as total_sold_quantity,
		rank() over(partition by division order by sum(sold_quantity) desc) as rank_order
from fact_sales_monthly s
join dim_product p on s.product_code=p.product_code
where fiscal_year=2021
group by division, s.product_code, product)

select * 
from cte
where rank_order<=3

/* output
N & S	A6720160103	AQ Pen Drive 2 IN 1	701373	1
N & S	A6818160202	AQ Pen Drive DRC	688003	2
N & S	A6819160203	AQ Pen Drive DRC	676245	3
P & A	A2319150302	AQ Gamers Ms	428498	1
P & A	A2520150501	AQ Maxima Ms	419865	2
P & A	A2520150504	AQ Maxima Ms	419471	3
PC	A4218110202	AQ Digit	17434	1
PC	A4319110306	AQ Velocity	17280	2
PC	A4218110208	AQ Digit	17275	3
*/
