use BikeStores

select* from [production].[brands]
select* from [production].[categories]
select* from [production].[products]
select* from [production].[stocks]
select* from [sales].[customers]
select * from [sales].[order_items]
select * from [sales].[orders]
select* from [sales].[staffs]
select* from [sales].[stores]









--1)Write down the price for each product; low, high,medium and calculate their ratio to the total.

declare @x float=( select Count(*) from production.products)

select price_category ,round((count(*)/@x)*100,2) as quantity_by_pricing from(

select *, case 
when list_price<1000 then 'Low'
when list_price<5000 then 'Medium'
when list_price>5000 then 'High'

else 'Unknow'
end as price_category

from production.products) as t1 

group by price_category


--2)How many products each store had by category before and after the sale.


SELECT t2.store_id, t2.category_id, pc.category_name, 
       t2.Quantity , t5.Reserves, 
       t2.Quantity + t5.Reserves AS starting_Quantity 
FROM (
  SELECT store_id, category_id, SUM(productIDquantity) AS Quantity 
  FROM (
    SELECT store_id, product_id, SUM(quantity) AS productIDquantity 
    FROM sales.orders AS so 
    LEFT JOIN sales.order_items soi ON soi.order_id = so.order_id  
    GROUP BY store_id, product_id
  ) AS t1 
  LEFT JOIN production.products AS pp ON t1.product_id = pp.product_id 
  GROUP BY category_id, store_id
) AS t2 
LEFT JOIN production.categories AS pc ON pc.category_id = t2.category_id 
LEFT JOIN (
  SELECT t4.store_id, t4.category_id, t4.Reserves, pc1.category_name 
  FROM (
    SELECT ps1.store_id, pp1.category_id, SUM(ps1.quantity) AS Reserves 
    FROM [production].[stocks] AS ps1 
    LEFT JOIN production.products AS pp1 ON pp1.product_id = ps1.product_id
    GROUP BY ps1.store_id, pp1.category_id
  ) AS t4 
  LEFT JOIN production.categories AS pc1 ON t4.category_id = pc1.category_id  
) AS t5 
ON t5.store_id = t2.store_id AND t5.category_id = pc.category_id
ORDER BY store_id;






--3)
--select the products delivered late on the requested date and see if there is any inefficiency 
--of any branch (number of late products/orders received in this store)




select ss2.store_id, ss2.store_name,t3.leted_orders,t3.order_quantity,t3.percent_late from (
select t.store_id,t.leted_orders,t2.order_quantity,
round(cast(t.leted_orders as float)/cast(t2.order_quantity as float)*100 ,2) as percent_late
from(
select store_id,COUNT(*) as leted_orders  from sales.orders
where not shipped_date<=required_date
group by store_id) as t
left join (

Select store_id, count(*) as order_quantity from sales.orders
group by store_id) as t2
on t.store_id=t2.store_id) as t3 right join sales.stores ss2
on ss2.store_id=t3.store_id

--4) count the average amount spent by each state.

select state,avg(order_value) avarage_spand from(
select order_id,sum(quantity*list_price*(1-discount) )as order_value from [sales].[order_items]
group by order_id) as t full join  sales.orders as so on
so.order_id=t.order_id left join sales.customers as sc 
on sc.customer_id=so.customer_id
group by state

---In this particular case, the users are from the state where they are buying the product,
---but this query would also calculate if they were from another state.


--5)
--Let's determine if any of the applicants lives on a street in which we can find his name or surname,
--or if he has served a staff under whom we can find his name.

select so.order_id,sc.customer_id,sc.first_name,sc.last_name,street,ss.staff_id,
ss.first_name as staff_firsName,
ss.last_name as staff_lastName into #table from [sales].[orders] as so left join
sales.customers as sc 
on sc.customer_id=so.customer_id left join sales.staffs as ss
on ss.staff_id=so.staff_id
------------------------------------------------------------------------

select  order_id,customer_id,first_name,last_name,
		street,staff_id,staff_firsName,staff_lastName 
from(

select *,CHARINDEX(first_name,street) as first_inex_s,
CHARINDEX (last_name,street) as last_index_s,
CHARINDEX(first_name,staff_firsName) as staf_name_index from #table)
as t
where  t.first_inex_s<>0 or t.last_index_s<>0 or t.staf_name_index<>0



drop table #table



