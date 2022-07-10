/*
Q1
   write at least 5 analytical SQL queries that tells a story about the data 
*/
select * from online_retail
limit 5;

-- 1- The most Items was purchased in each country:
select distinct description,country, sum(quantity) over(partition by stockcode order by quantity desc) as Quantityx
from online_retail
where description!=''
order by 3 desc;

-- 2- Top Five Invoiceno per total price
update online_retail
set Totalprice= quantity * unitprice

select Distinct Customerid , invoiceno , country , sum(Totalprice) over(partition by (customerid , invoiceno , country)) as TOT_PRC
from online_retail
where invoiceno not like 'C_' and customerid !=''
order by TOT_PRC Desc
limit 5;

-- 3- Total Sales Per Country For Quarter and years
Select distinct (TO_CHAR(to_date(invoicedate,'mm/dd/yy'), '"Quarter: "FMQ, "of year: "FMYYYY')) As Q_Years, Country,
	Sum(totalprice)over(partition by ((TO_CHAR(to_date(invoicedate,'mm/dd/yy'), '"Quarter: "FMQ, "of year: "FMYYYY')),COuntry)) AS TOT_SALE_Q_Y  
from online_retail
order by 2,3 desc

-- Total Sales's day for each country
Select distinct (TO_CHAR(to_date(invoicedate,'mm/dd/yy'), 'DAY')), Country,
	Sum(totalprice)over(partition by (TO_CHAR(to_date(invoicedate,'mm/dd/yy'), 'Day'))) AS TOT_SALE_DAY  
from online_retail
order by 2,3 desc

-- 4- Minimum and maximum Sales Per Customers
select distinct customerid , Max(totalprice) over(partition by customerid) "Maximum Sales" ,
		Min(totalprice) over(partition by customerid) "Minimum Sales"
from online_retail
where invoiceno not like 'C%' and customerid !=''


-- 5- First and  Last Transaction per customer
Select distinct customerid ,
		first_value(invoicedate) over(partition by invoiceno order by invoicedate)  as "First Transction",
		last_value(invoicedate) over(partition by invoiceno order by invoicedate 
									rows between unbounded preceding and unbounded following)  as "Last Transction"
		
from online_retail


-- 5- Minimum and Maximum Sales per customers

select distinct customerid , Max(totalprice) over(partition by customerid) "Maximum Sales" ,
		Min(totalprice) over(partition by customerid) "Minimum Sales"
from online_retail
where invoiceno not like 'C%' and customerid !=''
order by customerid


/************************************************************************

Q2:
 After exploring the data now you are required to implement a Monetary model for 
 customers behavior for product purchasing and segment each customer based on the 
 below groups
*/
select 
customerid,Recency,frequincy,Monetary,rscore,fmscore,
		case 
			when ((rscore+fmscore)>=9) then 'Champions'
			when (rscore =5 and fmScore =2 ) or (rscore =4 and fmScore =2) 
			or (rscore =3 and fmScore =3) or (rscore =4 and fmScore =3) then 'Potential Loyalists'
			when (rscore =5 and fmScore =3 ) or (rscore =4 and fmScore =4) 
			or (rscore =3 and fmScore =5) or (rscore =3 and fmScore =4) then 'Loyal Customers'
			when (rscore =5 and fmScore =1 )then 'Recent Customers'
			when (rscore =4 and fmScore =1 ) or (rscore =3 and fmScore =1) then 'Promising'
			when (rscore =3 and fmScore =2 ) or (rscore =2 and fmScore =3) 
			or (rscore =2 and fmScore =2) then 'Customers Needing Attention'
			when (rscore =2 and fmScore =5 ) or (rscore =2 and fmScore =4) 
			or (rscore =1 and fmScore =3) then 'At Risk'
			when (rscore =1 and fmScore =5 ) or (rscore =1 and fmScore =4)  then 'Cant Lose Them'
			when ((rscore + fmScore)=3 )then 'Hibernating'
			when ((rscore +fmScore) <=2 ) then 'Lost'	
		end as "Customer Segment"
from (
with CTE_AGG as (
	select customerid,recency,frequincy,monetary,
				ntile(5)over( order by recency desc)as rscore,
				((frequincy+monetary)/2)::numeric(10) as fmscore
	from(
		select 
			distinct customerid,
			(select max(to_date(invoicedate,'mm/dd/yy')) from online_retail)- 
				max(to_date(invoicedate,'mm/dd/yy'))over(partition by customerid ) as Recency,
			 count(invoiceno) over(partition by customerid) as frequincy,
			 
				sum(unitprice)over(partition by customerid)::numeric(10,2) as Monetary
		from online_retail 
	 	where customerid!=''
		)innerSUb 
	group by customerid,Recency,frequincy,Monetary)
select* from CTE_AGG) sub
order by monetary,customerid desc;


/******************************************************************/
