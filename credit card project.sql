
--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends

SELECT TOP 5 
 city,
 SUM(amount) AS total_spent,
 ROUND(SUM(amount) * 100.0 / 
 (SELECT SUM(amount) FROM credit_card_transcations) , 2) AS percentage_contribution
FROM 
credit_card_transcations
GROUP BY 
city
ORDER BY 
total_spent DESC;

--alternaive

	with cte1 as (
select city,sum(amount) as total_spend
from credit_card_transcations
group by city)
,total_spent as (select sum(cast(amount as bigint)) as total_amount from credit_card_transcations)
select top 5 cte1.*, round(total_spend*1.0/total_amount * 100,2) as percentage_contribution from 
cte1 inner join total_spent on 1=1
order by total_spend desc


--2 Highest spend month and amount spent in that month for each card type

with cte as (select card_type,datepart(year,date) yt
,datepart(month,date) mt,sum(amount) as total_spend
from credit_card_transcations
group by card_type,datepart(year,date),datepart(month,date))

select * from (select *, rank() over(partition by card_type order by total_spend desc) as rn
from cte) a where rn=1

--3-  The transaction details(all columns from the table) for each card type when it reaches 
--    a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (select *,sum(amount) over(partition by card_type order by date,[index]) as total_spend
from credit_card_transcations
)
select * from (select *, rank() over(partition by card_type order by total_spend) as rn  
from cte where total_spend >= 1000000) a where rn=1

-- City which had lowest percentage spend for gold card type
 
with cte as (
select  city,card_Type,sum(amount) as amount
,sum(case when card_Type='Gold' then amount end) as gold_amount
from credit_card_transcations
group by city,card_Type)
select top 1
city,sum(  gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having count(gold_amount)> 0 and sum(gold_amount)>0
order by gold_ratio;


--write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte as (
select city,exp_type, sum(amount) as total_amount from credit_card_transcations
group by city,exp_type)
select
city , max(case when rn_asc=1 then exp_type end) as lowest_exp_type
, min(case when rn_desc=1 then exp_type end) as highest_exp_type
from
(select *
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from cte) A
group by city;

-- Percentage contribution of spends by females for each expense type

select exp_type,
(sum(case when gender='F' then amount else 0 end)*1.0/sum(amount))*100 as percentage_female_contribution
from credit_card_transcations
group by exp_type
order by percentage_female_contribution desc;

--which card and expense type combination saw highest month over month growth in Jan-2014

with cte as (
select card_type,exp_type,datepart(year,date) yt
,datepart(month,date) mt,sum(amount) as total_spend
from credit_card_transcations
group by card_type,exp_type,datepart(year,date),datepart(month,date)
)
select   *, (total_spend-prev_mont_spend) as mom_growth
from (
select *
,lag(total_spend,1) over(partition by card_Type,exp_type order by yt,mt) as prev_mont_spend
from cte) A
where prev_mont_spend is not null and yt=2014 and mt=1
order by mom_growth desc

-- which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte as (
select *
,row_number() over(partition by city order by date,[index]) as rn
from credit_card_transcations)
select top 1 city,datediff(day,min(date),max(date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1 

-- During weekends which city has highest total spend to total no of transcations ratio 
select top 1 city , sum(amount)*1.0/count(1) as ratio
from credit_card_transcations
where datepart(weekday,date) in (1,7)
--where datename(weekday,transaction_date) in ('Saturday','Sunday')
group by city
order by ratio desc;

--Which city has the most consistent monthly spending pattern?
WITH monthly_spend AS (
  SELECT 
    city, 
    FORMAT(date, 'yyyy-MM') AS month,  
    SUM(amount) AS total_spend
  FROM credit_card_transcations
  GROUP BY city, FORMAT(date, 'yyyy-MM')
),
spend_variability AS (
  SELECT 
    city, 
    COUNT(*) AS months_count,
    STDEV(total_spend) AS std_dev_spend
  FROM monthly_spend
  GROUP BY city
  HAVING COUNT(*) > 1  
)
SELECT TOP 1 *
FROM spend_variability
ORDER BY std_dev_spend ASC;

--Average transaction size by gender and card type
SELECT gender, card_type,
       AVG(amount) AS avg_transaction_value,
       COUNT(*) AS num_transactions
FROM credit_card_transcations
GROUP BY gender, card_type
ORDER BY avg_transaction_value DESC;


