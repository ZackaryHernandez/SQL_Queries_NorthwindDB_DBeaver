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
HAVING Sum(Quantity * UnitPrice) > 10000 ORDER BY TotalOrderAmount DESC;



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
SELECT c.CustomerID AS Customers_CustomerID,
       o.CustomerID AS Orders_OrdersID
FROM Customers c
	LEFT JOIN Orders o 
		ON c.CustomerID = o.CustomerID
WHERE c.CustomerID NOT IN(SELECT CustomerID FROM Orders)




#29 Employee Order Detail Report
#Goal:  joining 3 tables together
# Employee ID (Employee Table) --> Employee ID (Orders Table) Order ID --> Order ID (Order Details Table) 

/*SELECT Employees.EmployeeID,
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
	*/

       


#28
#Moral: Do not hard code dates in where conditions
SELECT ShipCountry,
	   AVG(Freight) AS AverageFreight
FROM Orders 
WHERE 
	 OrderDate >= DATE_ADD((Select max(OrderDate) from Orders) , INTERVAL -1 year)
GROUP BY ShipCountry
ORDER BY AverageFreight DESC 
LIMIT 3;

#27 Given from file - this query provides a different average weight
#because BETWEEN Operator does non inclusive for 12-31
# subquery 27a shows 408 
# subquery 27b shows 406 rows. this query matches the "incorrect" query below
# 2 rows are from 12-31 and one of them is france
#the OrderID for this missing France row is 10,806
# Moral of the story: BETWEEN is non inclusive for the upper limit
# it only includes 2015-12-31 00:00:00. it doe include times after 00:00:00 on the 31st
# if this was a date field instead of a datetime field, between would have workded fine. 

SELECT ShipCountry,
	   AVG(Freight) AS AverageFreight
FROM Orders
WHERE
	OrderDate BETWEEN '2015-01-01' AND '2015-12-31'
GROUP BY ShipCountry
ORDER BY AverageFreight DESC
LIMIT 5;

#27a using comparison operators: gives us 408 results
/*
SELECT ShipCountry,
	OrderID,
	OrderDate
FROM Orders o 
WHERE OrderDate >= '2015-01-01' 
	AND 
		OrderDate < '2016-01-01'
ORDER BY OrderDate DESC 
*/

#27b Gives us 406 results
/*SELECT ShipCountry,
	OrderID,
	OrderDate
FROM Orders
WHERE
	OrderDate BETWEEN '2015-01-01' AND '2015-12-31'
ORDER BY OrderDate DESC

 #26
SELECT ShipCountry,
	   AVG(Freight) AS AverageFreight
FROM Orders
WHERE
	OrderDate >= '2015-01-01'
	AND 
	OrderDate < '2016-01-01'
GROUP BY ShipCountry
ORDER BY AverageFreight DESC
LIMIT 5;*/

         



/*
CASE (
		 	WHEN (YEAR(OrderDate) = 2015
		 		THEN 3000
		 		ELSE YEAR(OrderDate)
		 	END) DESC
*/



	   


/*#25
 * 
 * SELECT ShipCountry,
       AVG(Freight) AS AverageFreight
FROM Orders
GROUP BY ShipCountry
ORDER BY AverageFreight DESC 
LIMIT 3;*/


/*
 * #24
 * SELECT CustomerID,
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
	   	Region ASC*/

/* #23
SELECT ProductID, 
	   ProductName,
	   UnitsInStock,
	   UnitsOnOrder,
	   ReorderLevel,
	   Discontinued 
FROM Products
WHERE ((UnitsInStock + UnitsOnOrder) <= ReorderLevel) AND Discontinued = 0*/ 

/* #22
SELECT ProductID, 
	   ProductName,
	   UnitsInStock,
	   ReorderLevel
FROM Products
WHERE UnitsInStock < ReorderLevel*/



/* #21

SELECT Country, City,
       COUNT(CustomerID) AS TotalCustomers
FROM Customers
GROUP BY Country, City 
*/




/*#20
SELECT CategoryName, COUNT(Products.CategoryID) AS TotalProducts
FROM Products
	JOIN Categories
	ON Products.CategoryID = Categories.CategoryID
GROUP BY CategoryName
ORDER BY TotalProducts DESC*/



/* #19
 * 
 * SELECT OrderID, 
	   DATE(OrderDate) AS OrderDate,
	   CompanyName AS Shipper
FROM Orders
	  JOIN Shippers
	  ON  Shippers.ShipperID = Orders.ShipVia 
WHERE 
	  OrderID < 10270
ORDER BY 
	  OrderDate ASC 
*
*
*/
    
	
/* #18
SELECT ProductID, 
	   ProductName, 
	   CompanyName 
FROM Products
	JOIN Suppliers
	ON Suppliers.SupplierID = Products.SupplierID
*
