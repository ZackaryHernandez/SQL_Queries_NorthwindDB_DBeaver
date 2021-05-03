#########################
# SQL Practice Problems
#57 beginning, intermediate, and advanced challenges for you to solve using a “learn-by-doing” approach
#MySQL version
#By Sylvia Moestl Vasilik

#Zack Hernandez
#########################

#57 Done    
#Customers with multiple orders in 5 day period, version 2
#There’s another way of solving the problem above, using a Window function. 
SELECT
    CustomerID
    ,DATE(OrderDate) as InitialOrderDate
    ,DATE(LEAD(OrderDate,1)
       OVER (PARTITION by CustomerID order by CustomerID, OrderDate)
     ) as NextOrderDate
    FROM Orders
)SELECT
	CustomerID
	,InitialOrderDate
	,NextOrderDate
	,DateDiff (NextOrderDate, InitialOrderDate) as DaysBetweenOrders
From NextOrderDate
Where
	DateDiff (NextOrderDate, InitialOrderDate ) <= 5;



#56 Customers with multiple orders in 5 day period
#There are some customers for whom freight is a major expense when ordering from Northwind.
#However, by batching up their orders, and making one larger order instead of multiple smaller orders in a short period of time,
# they could reduce their freight costs significantly.
#Show those customers who have made more than 1 order in a 5 day period. 
#The sales people will use this to help customers reduce their freight costs.
#Note: There are more than one way of solving this kind of problem. For this problem, we will not be using Window functions.
#Moral: When comparing items in the same table join on the same table with different alias'
#and use the where claus to draw comparisons between Initial and Final Data. 
Select
	InitialOrder.CustomerID
	,InitialOrder.OrderID as InitialOrderID 
	,Date(InitialOrder.OrderDate) as InitialOrderDate 
	,NextOrder.OrderID as NextOrderID 
	,Date(NextOrder.OrderDate) as NextOrderDate 
	,DateDiff(NextOrder.OrderDate, InitialOrder.OrderDate) as DaysBetweenOrders
FROM Orders InitialOrder
	JOIN Orders NextOrder
		ON InitialOrder.CustomerID = NextOrder.CustomerID
WHERE
	InitialOrder.OrderID < NextOrder.OrderID
	and
	DateDiff(NextOrder.OrderDate, InitialOrder.OrderDate) <= 5
Order by 
	InitialOrder.CustomerID,
	InitialOrder.OrderID;

#55 First order in each country
#Looking at the Orders table—we’d like to show details for each order 
#that was the first in that particular country, ordered by OrderID.
#So, for each country, we want one row. That row should contain the
# earliest order for that country, with the associated
# ShipCountry, CustomerID, OrderID, and OrderDate.

#THREW IN THE TOWEL. Window functions to solve the problem.


with OrdersByCountry as (
    Select
        ShipCountry
        ,CustomerID
        ,OrderID
        ,Date(OrderDate) as OrderDate
        ,Row_Number()
            over (Partition by ShipCountry)
            as RowNumberPerCountry
    From Orders
) Select
    ShipCountry
    ,CustomerID
    ,OrderID
    ,OrderDate
From OrdersByCountry
Where
RowNumberPerCountry = 1 Order by
    ShipCountry;


#54 Countries with suppliers or customers, version 3
# The output in the above practice problem is improved, but it’s still not ideal
#What we’d really like to see is the country name, the total suppliers, and the total customers.
# Moral: Alter distinct cte to a group by cte to get count of countries. 
WITH AllCountries AS 
		(SELECT Country FROM Suppliers
		Union
		SELECT Country FROM Customers)
	,SupplierCountries AS
		(SELECT 
			Country,
			COUNT(*) AS TotalSuppliers
		 FROM Suppliers
		 GROUP BY 
		 	Country)
	,CustomerCountries AS
    	(SELECT 
    		Country,
    		COUNT(*) AS TotalCustomers
    	 FROM Customers
    	 GROUP BY Country)
SELECT
	AllCountries.Country AS AllCountries,
	IFNULL(SupplierCountries.TotalSuppliers, 0) AS TotalSuppliers,
	IFNULL(CustomerCountries.TotalCustomers, 0) AS TotalCustomers
FROM AllCountries 
	Left Join CustomerCountries
		ON AllCountries.Country = CustomerCountries.Country
	Left Join SupplierCountries
		ON AllCountries.Country = SupplierCountries.Country
Order by AllCountries.Country;

#53 Countries with suppliers or customers, version 2
# The employees going on the business trip don’t want just a raw list of countries, they want more details. 
# We’d like to see output like the below, in the Expected Results.
#Begin by creating a country CTE that is a union of both country columns. 
#Then make separate CTEs that represent distinct supplier countries and distinct customer countries/
#Join these distinct CTEs together on the unioned column. This works because the union column has all possible countries.
#We can now select colums from AllCountries (unioned column) and the other two distinct columns. 

WITH AllCountries AS 
		(SELECT Country FROM Suppliers
		Union
		SELECT Country FROM Customers)
	,SupplierCountries AS
		(SELECT DISTINCT Country FROM Suppliers)
	,CustomerCountries AS
    	(SELECT DISTINCT Country FROM Customers)
SELECT
	AllCountries.Country AS AllCountries,
	SupplierCountries.Country AS SupplierCountry,
	CustomerCountries.Country AS CustomerCountry
FROM AllCountries 
	Left Join CustomerCountries
		ON AllCountries.Country = CustomerCountries.Country
	Left Join SupplierCountries
		ON AllCountries.Country = SupplierCountries.Country
Order by AllCountries.Country;


	

#52 Countries with suppliers or customers
#Some Northwind employees are planning a business trip, and would like to visit as many suppliers and customers as possible. 
#Moral of the story: UNION to combine two columns together with distinct values.
#UNION ALL for non-distinct values included (all values)
SELECT 	
	Country
FROM Customers c  
Union
SELECT 
	Country
FROM Suppliers s 
ORDER BY Country;



#51. Customer grouping—flexible
#Andrew, the VP of Sales is still thinking about how best to group customers, 
#and define low, medium, high, and very high value customers.
# He now wants complete flexibility in grouping the customers,
# based on the dollar amount they've ordered. 
#He doesn’t want to have to edit SQL in order to change the boundaries of the customer groups.
#There's a table called CustomerGroupThreshold that you will need to use. Use only orders from 2016.

#Analysis: The key question I asked myself is how am I going to join CustomerGroupThresholds table
#on to Orders2016 CTE when there is no matching primary key?
#the answer is to join Orders2016.TotalOrderAmount on 2 fields that are represent an upper and lower limit. 
# Range bottom and range top. 
SELECT *
FROM CustomerGroupThresholds cgt 

WITH Orders2016 AS (
SELECT
	c.CustomerID,
	c.CompanyName,
	SUM(Quantity * UnitPrice) as TotalOrderAmount
FROM Customers c
	JOIN Orders o
		ON c.CustomerID = o.CustomerID 
	JOIN OrderDetails od 
		ON o.OrderID = od.OrderID 
WHERE OrderDate >= '2016-01-01' and OrderDate < '2017-01-01'
GROUP BY 
	c.CustomerID,
	c.CompanyName
)
SELECT 
	CustomerID,
    CompanyName,
    TotalOrderAmount,
    CustomerGroupName
FROM Orders2016
	JOIN CustomerGroupThresholds
		ON Orders2016.TotalOrderAmount BETWEEN 
		CustomerGroupThresholds.RangeBottom 
		AND 
		CustomerGroupThresholds.RangeTop 
ORDER BY 
	CustomerID;
	



#50 Customer grouping with percentage
#Based on the above query, show all the defined CustomerGroups, and the percentage in each. 
#Sort by the total in each group, in descending order.
#added an intermediate CTE called CustomerGrouping.
#CustomerGrouping is referenced twice—once to get the total number of customers in the specific group, 
#and once to get the total, as the denominator for the percentage.
with Orders2016 as (
    Select
		Customers.CustomerID
		,Customers.CompanyName
		,SUM(Quantity * UnitPrice) as TotalOrderAmount
    From Customers
        Join Orders
			on Orders.CustomerID = Customers.CustomerID 
		Join OrderDetails
			on Orders.OrderID = OrderDetails.OrderID
Where OrderDate >= '2016-01-01' and OrderDate < '2017-01-01'
Group by 
	Customers.CustomerID,
	Customers.CompanyName
),CustomerGrouping as (
    Select
        CustomerID
        ,CompanyName
        ,TotalOrderAmount
        ,Case
			when TotalOrderAmount >= 0 and TotalOrderAmount < 1000 then 'Low'
			when TotalOrderAmount >= 1000 and TotalOrderAmount < 5000 then 'Medium'
			when TotalOrderAmount >= 5000 and TotalOrderAmount <10000 then 'High'
			when TotalOrderAmount >= 10000 then 'Very High'
        End
            as CustomerGroup
    from Orders2016
)
Select
    CustomerGroup
    ,Count(*) as TotalInGroup
    ,Count(*)/(select count(*) from CustomerGrouping)
        as PercentageInGroup
from CustomerGrouping
group by CustomerGroup
order by TotalInGroup  desc;




#49 Customer grouping—fix null
#Fix the null value. Since TotalOrderAmount is a decimal, use comparison operators. 
#Using “between” would have been fine for integer values, but not for decimal.
with Orders2016 as (
    Select
		Customers.CustomerID
		,Customers.CompanyName
		,SUM(Quantity * UnitPrice) as TotalOrderAmount
    From Customers
        Join Orders
			on Orders.CustomerID = Customers.CustomerID 
		Join OrderDetails
			on Orders.OrderID = OrderDetails.OrderID
Where OrderDate >= '2016-01-01' and OrderDate < '2017-01-01'
Group by 
	Customers.CustomerID,
	Customers.CompanyName
) Select
    CustomerID
    ,CompanyName
    ,TotalOrderAmount
    ,Case
        when TotalOrderAmount >= 0 and TotalOrderAmount < 1000 then 'Low'
		when TotalOrderAmount >= 1000 and TotalOrderAmount < 5000 then 'Medium'
		when TotalOrderAmount >= 5000 and TotalOrderAmount < 10000 then 'High'
		when TotalOrderAmount >= 10000 then 'Very High'
    End
        as CustomerGroup
from Orders2016
Order by CustomerID;



#48
#Customer grouping
#Andrew Fuller, the VP of sales at Northwind, would like to do a sales campaign for existing customers. 
#He'd like to categorize customers into groups, based on how much they ordered in 2016. 
#Then, depending on which group the customer is in, he will target the customer with different sales materials.
#The customer grouping categories are 0 to 1,000, 1,000 to 5,000, 5,000 to 10,000, and over 10,000. 
#So, if the total dollar amount of the customer’s purchases in that year were between 0 to 1,000, they would be in the “Low” group. 
#A customer with purchase from 1,000 to 5,000 would be in the “Medium” group, and so on.
#A good starting point for this query is the answer from the problem “High-value customers— total orders”. Also, we only want to show customers who have ordered in 2016.
# Order the results by CustomerID.

# my answer
SELECT c.CustomerID,
       c.CompanyName, 
       SUM(Quantity * UnitPrice) AS TotalOrderAmount,
       CASE
       	WHEN SUM(Quantity * UnitPrice) < 1000 THEN 'LOW'
       	WHEN SUM(Quantity * UnitPrice) >= 1000 AND SUM(Quantity * UnitPrice) < 5000 THEN 'MEDIUM'
       	WHEN SUM(Quantity * UnitPrice) >= 5000 AND SUM(Quantity * UnitPrice) < 10000 THEN 'HIGH'
       	ELSE 'EXTREMELY HIGH'
       	END AS CustomerGroup
FROM Customers c
    JOIN Orders o
		ON o.CustomerID = c.CustomerID 
	JOIN OrderDetails od
		ON o.OrderID = od.OrderID
WHERE
OrderDate >= '2016-01-01' and OrderDate < '2017-01-01'
GROUP BY 
	c.CustomerID,
	c.CompanyName 
ORDER BY CustomerID;

#Sylvias answer to 48:
#the benefit of using a CTE here is to not repeat the SUM(Quantity * UnitPrice) calculation.
# notice in my query I repeated it 5 times. IN Sylvia's query it is only done once. 
# this plays into the concept of DRY: don't repeat yourself. 

with Orders2016 as (
    Select
		Customers.CustomerID
		,Customers.CompanyName
		,SUM(Quantity * UnitPrice) as TotalOrderAmount
    From Customers
        Join Orders
			on Orders.CustomerID = Customers.CustomerID 
		Join OrderDetails
			on Orders.OrderID = OrderDetails.OrderID
Where OrderDate >= '2016-01-01' and OrderDate < '2017-01-01'
Group by 
	Customers.CustomerID,
	Customers.CompanyName
) Select
    CustomerID
    ,CompanyName
    ,TotalOrderAmount
    ,Case
        when TotalOrderAmount between 0 and 1000 then 'Low'
        when TotalOrderAmount between 1001 and 5001 then 'Medium'
        when TotalOrderAmount between 5001 and 10000 then 'High'
        when TotalOrderAmount >= 10000 then 'Very High'
    End
        as CustomerGroup
from Orders2016
Order by CustomerID;



  


#47 Late orders vs. total orders—fix decimaL
#You could also use format below in place of cast. 
#FORMAT(IFNULL(LateOrders.TotalOrders, 0) / AllOrders.TotalOrders, 2) AS PercentLateOrders
WITH LateOrders AS (
    SELECT
        EmployeeID,
        Count(*) AS TotalOrders
    FROM Orders
    WHERE RequiredDate <= ShippedDate 
    GROUP BY 
		  EmployeeID 
	),
AllOrders AS ( 
	SELECT
        EmployeeID,
        Count(*) AS TotalOrders
    FROM Orders
    GROUP BY
        EmployeeID
    )
SELECT
	Employees.EmployeeID,
	LastName,
	AllOrders.TotalOrders AS AllOrders, 
	IFNULL(LateOrders.TotalOrders, 0) AS LateOrders,
	CAST(
		IFNULL(LateOrders.TotalOrders, 0) / AllOrders.TotalOrders 
		AS Decimal(4, 2) )
		AS PercentLateOrders
FROM Employees
    LEFT JOIN AllOrders
		ON AllOrders.EmployeeID = Employees.EmployeeID 
	LEFT JOIN LateOrders
		ON LateOrders.EmployeeID = Employees.EmployeeID 
ORDER BY 
	Employees.EmployeeID;

#46Late orders vs. total orders—percentage
#Now we want to get the percentage of late orders over total orders.
#In some other database systems (such as SQL Server), you would need to explicitly convert one of the 
#fields to a decimal datatype, or implicitly convert them by multiplying by 1.0 in 
#order to get a decimal output.
WITH LateOrders AS (
    SELECT
        EmployeeID,
        Count(*) AS TotalOrders
    FROM Orders
    WHERE RequiredDate <= ShippedDate 
    GROUP BY 
		  EmployeeID 
	),
AllOrders AS ( 
	SELECT
        EmployeeID,
        Count(*) AS TotalOrders
    FROM Orders
    GROUP BY
        EmployeeID
    )
SELECT
	Employees.EmployeeID,
	LastName,
	AllOrders.TotalOrders AS AllOrders, 
	IFNULL(LateOrders.TotalOrders, 0) AS LateOrders,
	IFNULL(LateOrders.TotalOrders, 0) / AllOrders.TotalOrders AS PercentLateOrders
FROM Employees
    LEFT JOIN AllOrders
		ON AllOrders.EmployeeID = Employees.EmployeeID 
	LEFT JOIN LateOrders
		ON LateOrders.EmployeeID = Employees.EmployeeID 
ORDER BY 
	Employees.EmployeeID;

#45
#Late orders vs. total orders—fix null
#Continuing on the answer for above query, let's fix the results for row 5 - Buchanan. 
#He should have a 0 instead of a Null in LateOrders.
#Moral use ifnull in the final select, not the CTE
WITH LateOrders AS (
    SELECT
        EmployeeID,
        Count(*) AS TotalOrders
    FROM Orders
    WHERE RequiredDate <= ShippedDate 
    GROUP BY 
		  EmployeeID 
	),
AllOrders AS ( 
	SELECT
        EmployeeID,
        Count(*) AS TotalOrders
    FROM Orders
    GROUP BY
        EmployeeID
    )
SELECT
	Employees.EmployeeID,
	LastName,
	AllOrders.TotalOrders AS AllOrders, 
	IFNULL(LateOrders.TotalOrders, 0) AS LateOrders
FROM Employees
    LEFT JOIN AllOrders
		ON AllOrders.EmployeeID = Employees.EmployeeID 
	LEFT JOIN LateOrders
		ON LateOrders.EmployeeID = Employees.EmployeeID 
ORDER BY 
	Employees.EmployeeID;


#####Resume Sylvias course
SELECT o.OrderID,
	   od.UnitPrice
FROM Orders o 
JOIN OrderDetails od
	ON o.OrderID = od.OrderID 

SELECT 
	o.OrderID,
	o.EmployeeID,
	CASE WHEN YEAR(OrderDate) = '2016' THEN SUM(od.UnitPrice) ELSE 0 END AS '2016_total',
	CASE WHEN YEAR(OrderDate) = '2015' THEN SUM(od.UnitPrice) ELSE 0 END AS '2015_total',
	CASE WHEN YEAR(OrderDate) = '2014' THEN SUM(od.UnitPrice) ELSE 0 END AS '2014_total'
FROM Orders o 
JOIN OrderDetails od 
	ON o.OrderID = od.OrderID
GROUP BY 
	o.OrderID,
	o.EmployeeID,
 	o.OrderDate;




#Break from Sylvia's Course
#Task: Daniel Fields provided a SQL Server query. Interpret this query:
#My interpretation:
#The first column [Vendor] containts a concatenated string that begins with v.vendor_name, then a single space, and then ends with vendor_id as a varchar of length 10 datatype. This is all one column. 
#Case statements 2021 down to 2013 function like this: If column year_for_period contains 'xxyy' then sum all corresponding values in the purchase_amount column. Else, (if the year is not 'xxyy', then 0.
#




Select 
	v.vendor_name + ' (' + CAST(J.vendor_id as varchar(10)) + ')' as [Vendor],
	CASE WHEN year_for_period = '2021' THEN sum(purchase_amount) ELSE 0 END as [2021],
	CASE WHEN year_for_period = '2020' THEN sum(purchase_amount) ELSE 0 END as [2020],
	CASE WHEN year_for_period = '2019' THEN sum(purchase_amount)  ELSE 0 END as [2019],
	CASE WHEN year_for_period = '2018' THEN sum(purchase_amount)  ELSE 0 END as [2018],
	CASE WHEN year_for_period = '2017' THEN sum(purchase_amount)  ELSE 0 END as [2017],
	CASE WHEN year_for_period = '2016' THEN sum(purchase_amount)  ELSE 0 END as [2016],
	CASE WHEN year_for_period = '2015' THEN sum(purchase_amount)  ELSE 0 END as [2015],
	CASE WHEN year_for_period = '2014' THEN sum(purchase_amount)  ELSE 0 END as [2014],
	CASE WHEN year_for_period = '2013' THEN sum(purchase_amount)  ELSE 0 END as [2013]
	INTO #TEMP
from p21_view_purchases_journal as J
	inner join vendor as v 
		on J.vendor_id = v.vendor_id
where J.vendor_id IN (@Vendor)
group by J.vendor_id, year_for_period, v.vendor_name

 

Select
	[Vendor],
	SUM([2021]) as [2021],
	SUM([2020]) as [2020],
	SUM([2019]) as [2019],
	SUM([2018]) as [2018],
	SUM([2017]) as [2017],
	SUM([2016]) as [2016],	
	SUM([2015]) as [2015],
	SUM([2014]) as [2014],
	SUM([2013]) as [2013]
from #TEMP
GROUP BY [Vendor]
Order by [Vendor] asc

 

drop table #TEMP


#44 Late Orders vs. Total Orders -- missing employee
#There's an employtee missing in the answer from the problem above. Fix the SQL to show all
#employees who have taken orders. 
#Buchanan is missing from the list because his late orders = NULL
#Buchanan was missing because we have been using inner joins. Instead we had to use
#left join for each join statement. This ensures all employees are accounted for even
# if they do not have any late orders (or no orders at all).

WITH LateOrders AS (
    SELECT
        EmployeeID
        ,Count(*) AS TotalOrders
    FROM Orders
    WHERE RequiredDate <= ShippedDate 
    GROUP BY 
		  EmployeeID 
	),
AllOrders AS ( 
	SELECT
        EmployeeID,
        Count(*) AS TotalOrders
    FROM Orders
    GROUP BY
        EmployeeID
    )
SELECT
	Employees.EmployeeID,
	LastName,
	AllOrders.TotalOrders AS AllOrders, 
	LateOrders.TotalOrders AS LateOrders
FROM Employees
    LEFT JOIN AllOrders
		ON AllOrders.EmployeeID = Employees.EmployeeID 
	LEFT JOIN LateOrders
		ON LateOrders.EmployeeID = Employees.EmployeeID 
ORDER BY 
	Employees.EmployeeID;
#43 Late Orders vs. Total Orders
#Andrew, the VP of Sales, has been doing some more thinking about the problem of late orders. He realizes
#that just looking at the number of orders arriving late for each salesperson is not a good idea. It needs
#to be compared againts the total number of orders per sales person. 

#Sylvia's solution (my solution is below) 
#Sylvia's Solution uses CTEs
With LateOrders as (
    Select
        EmployeeID
        ,Count(*) as TotalOrders
    From Orders
    Where RequiredDate <= ShippedDate 
    Group By
		  EmployeeID 
	)
,AllOrders as ( 
	Select
        EmployeeID
        ,Count(*) as TotalOrders
    From Orders
    Group By
        EmployeeID
    )
SELECT
	Employees.EmployeeID
	,LastName
	,AllOrders.TotalOrders as AllOrders 
	,LateOrders.TotalOrders as LateOrders
From Employees
    Join AllOrders
		on AllOrders.EmployeeID = Employees.EmployeeID 
	Join LateOrders
		on LateOrders.EmployeeID = Employees.EmployeeID 
Order by 
	Employees.EmployeeID;

#My Solution: Create a temporary table contains TotalOrders with EmployeeID as the Primary Key
# Then, Join this temporary table 
SELECT 
	e.EmployeeID,
	e.LastName,
	t.TotalOrders,
	COUNT(*) AS TotalLateOrders
FROM Orders o
JOIN Employees e 
	ON o.EmployeeID = e.EmployeeID 
JOIN tempAllOrders t
	ON e.EmployeeID = t.EmployeeID
WHERE o.RequiredDate <= o.ShippedDate
GROUP BY 
	e.EmployeeID,
	e.LastName,
	t.TotalOrders
ORDER BY 
	EmployeeID 

#Testing the temporary table
SELECT *
FROM tempAllOrders

#Creating a temp table that will soon be joined to
CREATE TEMPORARY TABLE tempAllOrders 
SELECT 
	EmployeeID,
	COUNT(*) AS TotalOrders
FROM Orders o 
GROUP BY
	EmployeeID 
ORDER BY 
	EmployeeID 



#42 Late Orders -- which Employees?
#Some Salespeople have more orders arriving late than others. Maybe they're not following up
#on the order process, and need more training. Which Salespeople have the most orders arriving late. 
SELECT 
	e.EmployeeID,
	e.LastName, 
	COUNT(o.OrderID) AS TotalLateOrders
FROM Orders o
JOIN Employees e 
	ON o.EmployeeID = e.EmployeeID 
WHERE o.RequiredDate <= o.ShippedDate
GROUP BY 
	e.EmployeeID,
	e.LastName 
ORDER BY 
	TotalLateOrders DESC 
	
#41 Late Orders
#Some customers are complaining about their orders arriving late. 
#Which orders are late? Sort the results by OrderID.
SELECT OrderID,
	DATE(OrderDate) AS OrderDate,
	DATE(RequiredDate) AS RequiredDate,
	DATE(ShippedDate) AS ShippedDate
FROM Orders
WHERE RequiredDate <= ShippedDate 
ORDER BY
	OrderID;


#40 Orders—accidental double-entry details, derived table
#Here's another way of getting the same results as in the previous problem,
# using a derived table instead of a CTE. 
#However, there's a bug in this SQL. It returns 20 rows instead of 16. Correct the SQL.

#Fixed SQL: (add distinct to the Select statement nested in the JOIN statement
Select
     OrderDetails.OrderID
    ,ProductID
    ,UnitPrice
    ,Quantity
    ,Discount
 From OrderDetails
 	 Join (
		Select DISTINCT 
			OrderID
		From OrderDetails
		Where 
			Quantity >= 60
		Group By 
			OrderID, 
			Quantity
		Having Count(*) > 1
		) 
		PotentialProblemOrders ON PotentialProblemOrders.OrderID = OrderDetails.OrderID
Order by 
	OrderID, 
	ProductID;




#39 Orders = accidental double entry details
#Based on the previous question, 
#we now want to show details of the order, 
#for orders that match the above criteria.

#Slyvia's Answer using CTEs:
WITH PotentialDuplicates AS (
Select
OrderID
From OrderDetails
Where Quantity >= 60
Group By OrderID, Quantity 
Having Count(*) > 1
)
Select
    OrderID
    ,ProductID
    ,UnitPrice
    ,Quantity
    ,Discount
From OrderDetails
Where
    OrderID in (Select OrderID from PotentialDuplicates)
Order by
    OrderID
    ,Quantity;


#My answer using SELECT statement nested in the Where Clause
SELECT 
	OrderID,
	ProductID,
	UnitPrice,
	Quantity,
	Discount
FROM OrderDetails od 
WHERE OrderID IN 
	(SELECT OrderID
	FROM OrderDetails
	WHERE Quantity >= 60
	GROUP BY OrderID,
			 Quantity
	Having Count(*) > 1)
ORDER BY 
	OrderID,
	Quantity;


#38 Orders - accidental double entry
/*Janet Leverling, one of the salespeople, has come to you with a request. She thinks that she accidentally
 * entered a line item twice on an order, each time with a different ProductID, but the same quantity.
 * She remembers that the quantity was 60 or more. Show all the OrderIDs with line items that match this, in order of OrderID.
 * */

SELECT 
	OrderID,
	COUNT(*)
FROM OrderDetails od 
WHERE Quantity >= 60
GROUP BY 
	OrderID,
	Quantity
HAVING COUNT(*) > 1
ORDER BY 
	OrderID


#37 Orders - Random Assortment
#The Northwind mobile app developers would now like to just get a random assortment of orders for beta testing on their app.
#Show a random set of 10 orders.
SELECT OrderID
FROM Orders 
ORDER BY
	RAND()
LIMIT 5;


#36
#The Northwind mobile app developers are testing an app that customers will use to show orders. 
#In order to make sure that even the largest orders will show up correctly on the app,
#they'd like some samples of orders that have lots of individual line items.
#Show the 10 orders with the most line items, in order of total line items.
SELECT 
	OrderID,
	Count(*) AS TotalOrderDetails
FROM OrderDetails od
GROUP BY
	OrderID 
ORDER BY 
	COUNT(*) DESC
LIMIT 10;

#35 Month End Orders
#At the end of the month. salespeople are likely to try much harder to get orders, to meet their month end quotas. 
#Show all orders made on the last day of the month. Order by EmployeeID and OrderID.
SELECT 
	EmployeeID,
	OrderID,
	DATE(OrderDate)
FROM Orders
WHERE OrderDate = LAST_DAY(OrderDate)
ORDER BY OrderDate ASC 

# 

#34 High Value Customers with Discount
#Change the 33 query to use the discount when calculating high-value customers. 
#Order by the total amount which includes the discount.
SELECT c.CustomerID,
       c.CompanyName, 
       SUM(Quantity * UnitPrice) AS TotalWithoutDiscount,
       SUM(Quantity * UnitPrice * (1 - Discount)) AS TotalWithDiscount
FROM Customers c
    JOIN Orders o
		ON o.CustomerID = c.CustomerID 
	JOIN OrderDetails od
		ON o.OrderID = od.OrderID
WHERE
OrderDate >= '2016-01-01' and OrderDate < '2017-01-01'
GROUP BY 
	c.CustomerID,
	c.CompanyName
HAVING TotalWithDiscount > 10000
ORDER BY TotalWithDiscount DESC;


#33 High Value customers total orders
#The manager has changed his mind. Instead of requiring that customers have at least one individual orders totaling $10,000 or more,
#he wants to define high-value customers as those who have orders totaling $15,000 or more in 2016. 
#How would you change the answer from 32 to the problem above?
#Answer: The key is to only group by CustomerID and Company Name. A given company could have different OrderID's.
#Therefore, by emitting the OrderID from grouping we allow for all orders to be aggegated per CompanyName/CustomerID. 
SELECT c.CustomerID,
       c.CompanyName, 
       SUM(Quantity * UnitPrice) AS TotalOrderAmount
FROM Customers c
    JOIN Orders o
		ON o.CustomerID = c.CustomerID 
	JOIN OrderDetails od
		ON o.OrderID = od.OrderID
WHERE
OrderDate >= '2016-01-01' and OrderDate < '2017-01-01'
GROUP BY 
	c.CustomerID,
	c.CompanyName
HAVING Sum(Quantity * UnitPrice) >= 15000 
ORDER BY TotalOrderAmount DESC;



#32 (Beginning of Advanced Problems)
#We want to send all of our high-value customers a special gift. We are defining 
#high value customers as those who've made at least 1 order with a total value
#(not including the discount) equal to $10,000 or more. We only want to consider
#orders made in 2016.

# Correct:
SELECT c.CustomerID,
       c.CompanyName, 
       o.OrderID, 
       SUM(Quantity * UnitPrice) AS TotalOrderAmount
FROM Customers c
    JOIN Orders o
		ON o.CustomerID = c.CustomerID 
	JOIN OrderDetails od
		ON o.OrderID = od.OrderID
WHERE
OrderDate >= '2016-01-01' and OrderDate < '2017-01-01'
GROUP BY 
	c.CustomerID,
	c.CompanyName,
	o.Orderid
HAVING Sum(Quantity * UnitPrice) > 10000 
ORDER BY TotalOrderAmount DESC;



#Incorrect
SELECT
	o.CustomerID,
	c.CompanyName,
	od.OrderID,
	SUM(UnitPrice * Quantity) AS TotalPriceBeforeDiscount
FROM OrderDetails od 
	LEFT JOIN Orders o 
		ON od.OrderID = o.OrderID 
	LEFT JOIN Customers c 
		ON o.CustomerID  = c.CustomerID 
WHERE 
	o.OrderDate BETWEEN '2016-01-01' AND '2017-01-01';
GROUP BY
	o.CustomerID,
	c.CompanyName,
	od.OrderID
HAVING Sum(UnitPrice* Quantity) > 10000 Order by TotalPriceBeforeDiscount DESC;
    
    

	




#31 Alternative
SELECT CustomerID
FROM Customers c 
WHERE 
     CustomerID NOT IN (SELECT CustomerID FROM Orders WHERE EmployeeID = 4);

#31 Customers with no orders for EmployeeID 4
SELECT c.CustomerID,
  	   o.CustomerID,
  	   o.EmployeeID 
FROM Customers c 
	LEFT JOIN Orders o 
		ON o.CustomerID = c.CustomerID
		AND EmployeeID = 4
WHERE 
	o.CustomerID IS null;




#30 
#There are some customers who have never actually placed an order. Show these customers.
SELECT c.CustomerID AS Customers_CustomerID,
       o.CustomerID AS Orders_OrdersID
FROM Customers c
	LEFT JOIN Orders o 
		ON c.CustomerID = o.CustomerID
WHERE c.CustomerID NOT IN(SELECT CustomerID FROM Orders)




#29 Employee Order Detail Report
#We're doing inventory, and need to show Employee and Order Detail information like the below, for all orders. Sort by OrderID and Product ID.
#Goal:  joining 3 tables together
# Employee ID (Employee Table) --> Employee ID (Orders Table) Order ID --> Order ID (Order Details Table) 

SELECT Employees.EmployeeID,
       Employees.LastName,
       Orders.OrderID,
       Products.ProductID,
       OrderDetails.Quantity   
FROM Employees 
	JOIN Orders 
		ON Employees.EmployeeID = Orders.EmployeeID 
	JOIN OrderDetails
		ON Orders.OrderID = OrderDetails.OrderID 
	JOIN Products
		ON OrderDetails.ProductID  = Products.ProductID
	

       


#28
#We're continuing to work on high freight charges. We now want to get the three ship countries with the highest average freight charges.
#But instead of filtering for a particular year, we want to use the last 12 months of order data, using as the end date the last OrderDate in Orders.
#Moral: Do not hard code dates in where conditions
SELECT ShipCountry,
	   AVG(Freight) AS AverageFreight
FROM Orders 
WHERE 
	 OrderDate >= DATE_ADD((Select max(OrderDate) from Orders) , INTERVAL -1 year)
GROUP BY ShipCountry
ORDER BY AverageFreight DESC 
LIMIT 3;

#27
#See query below (***) this is provided by Sylvia and is incorrect
#Notice when you run this, it gives Sweden as the ShipCountry with the third highest freight charges. However, this is wrong—it should be France.
#Find the OrderID that is causing the SQL statement above to be incorrect.

#My notes: 
# BETWEEN Operator is non inclusive for 12-31
# subquery 27a shows 408 
# subquery 27b shows 406 rows. this query matches the "incorrect" query below provided by Sylvia (***)
#2 rows are from 12-31 and one of them is france the OrderID for this missing France row is 10,806

# Moral of the story: BETWEEN is non inclusive for the upper limit
# it only includes 2015-12-31 00:00:00. it doe include times after 00:00:00 on the 31st
# if this was a date field instead of a datetime field, between would have workded fine. 

# (***)( Given from file - this query provides a different average weight
SELECT ShipCountry,
	   AVG(Freight) AS AverageFreight
FROM Orders
WHERE
	OrderDate BETWEEN '2015-01-01' AND '2015-12-31'
GROUP BY ShipCountry
ORDER BY AverageFreight DESC
LIMIT 5;

#27a using comparison operators: gives us 408 results
SELECT ShipCountry,
	OrderID,
	OrderDate
FROM Orders o 
WHERE OrderDate >= '2015-01-01' 
	AND 
		OrderDate < '2016-01-01'
ORDER BY OrderDate DESC 


#27b Gives us 406 results
SELECT ShipCountry,
	OrderID,
	OrderDate
FROM Orders
WHERE
	OrderDate BETWEEN '2015-01-01' AND '2015-12-31'
ORDER BY OrderDate DESC

#26
#We're continuing on the question above on high freight charges. Now, instead of using all the orders we have, we only want to see orders from the year 2015.
SELECT ShipCountry,
	   AVG(Freight) AS AverageFreight
FROM Orders
WHERE
	OrderDate >= '2015-01-01'
	AND 
	OrderDate < '2016-01-01'
GROUP BY ShipCountry
ORDER BY AverageFreight DESC
LIMIT 5;
         



CASE (
		 	WHEN (YEAR(OrderDate) = 2015
		 		THEN 3000
		 		ELSE YEAR(OrderDate)
		 	END) DESC



	   


#25 
# Some of the countries we ship to have very high freight charges.
#We'd like to investigate some more shipping options for our customers, to be able to offer them lower freight charges.
# Return the three ship countries with the highest average freight overall, in descending order by average freight.
SELECT ShipCountry,
       AVG(Freight) AS AverageFreight
FROM Orders
GROUP BY ShipCountry
ORDER BY AverageFreight DESC 
LIMIT 3;
 

#24
#A salesperson for Northwind is going on a business trip to visit customers. He would like to see a list of all customers, sorted by region, alphabetically.
#However, he wants the customers with no region (null in the Region field) to be at the end, instead of at the top, where you’d normally find the null values.
#Within the same region, companies should be sorted by CustomerID.
SELECT CustomerID,
	   CompanyName,
	   Region,
	   (CASE
	   		WHEN Region is NULL THEN 1
	   		ELSE 0 
	   	END)
FROM Customers  
Order By (CASE
	   		WHEN Region is NULL THEN 1
	   		ELSE 0 
	   	END) ASC, 
	   	Region ASC

#23 
#Now we need to incorporate these fields—UnitsInStock, UnitsOnOrder, ReorderLevel, Discontinued—into our calculation.
#We’ll define “products that need reordering” with the following:
#UnitsInStock plus UnitsOnOrder are less than or equal to ReorderLevel
#The Discontinued flag is false.
SELECT ProductID, 
	   ProductName,
	   UnitsInStock,
	   UnitsOnOrder,
	   ReorderLevel,
	   Discontinued 
FROM Products
WHERE ((UnitsInStock + UnitsOnOrder) <= ReorderLevel) AND Discontinued = 0

#22
#What products do we have in our inventory that should be reordered? 
#For now, just use the fields UnitsInStock and ReorderLevel, where UnitsInStock is less than or equal to the ReorderLevel,
#Ignore the fields UnitsOnOrder and Discontinued.
#Sort the results by ProductID.

SELECT ProductID, 
	   ProductName,
	   UnitsInStock,
	   ReorderLevel
FROM Products
WHERE UnitsInStock < ReorderLevel*/



#21
#In the Customers table, show the total number of customers per Country and City.


SELECT Country, City,
       COUNT(CustomerID) AS TotalCustomers
FROM Customers
GROUP BY Country, City 





#20
#For this problem, we’d like to see the total number of products in each category. Sort the results by the total number of products, in descending order.
SELECT CategoryName, COUNT(Products.CategoryID) AS TotalProducts
FROM Products
	JOIN Categories
	ON Products.CategoryID = Categories.CategoryID
GROUP BY CategoryName
ORDER BY TotalProducts DESC



#19 
#We’d like to show a list of the Orders that were made, including the Shipper that was used. 
#Show the OrderID, OrderDate (date only), and CompanyName of the Shipper, and sort by OrderID.
#In order to not show all the orders (there’s more than 800), show only those rows with an OrderID of less than 10270.
SELECT OrderID, 
	   DATE(OrderDate) AS OrderDate,
	   CompanyName AS Shipper
FROM Orders
	  JOIN Shippers
	  ON  Shippers.ShipperID = Orders.ShipVia 
WHERE 
	  OrderID < 10270
ORDER BY 
	  OrderDate ASC 
    
	
#18
#We’d like to show, for each product, the associated Supplier. Show the ProductID, ProductName, and the CompanyName of the Supplier.
#Sort the result by ProductID.
#This question will introduce what may be a new concept—the Join clause in SQL.
#The Join clause is used to join two or more relational database tables together in a logical way.
#Here’s a data model of the relationship between Products and Suppliers.
SELECT ProductID, 
	   ProductName, 
	   CompanyName 
FROM Products
	JOIN Suppliers
	ON Suppliers.SupplierID = Products.SupplierID
	
	
#Questions 1 through 17 were Beginner level select statememnts. All questions above are increasingly more advanced.  
