select * from Customers
select * from Exchange_Rates
select * from Products
select * from Sales
select * from Stores

--==========================================

-- Handle Null values in Delivery date
select  Avg ( DATEDIFF ( DAY , Order_Date , Delivery_Date )) as AVG_DIFF_DAYS
from Sales Where Delivery_Date is not Null and Order_Date is not Null

UPDATE Sales
SET Delivery_Date = DATEADD(DAY, 8, Order_Date)
WHERE Delivery_Date IS NULL;

--===================================================================

-- Total Reveneu
select Sum (Unit_Price_USD * Quantity) As Total_Reveneau
from Products P join Sales S
on P.ProductKey = S.ProductKey

--Total Cost
select Sum (Unit_Cost_USD * Quantity) As Total_Cost
from Products P join Sales S
on P.ProductKey = S.ProductKey

--Total Profit
select Sum ((Unit_Price_USD * Quantity)-(Unit_Cost_USD * Quantity) ) As Total_Profit 
from Products P join Sales S
on P.ProductKey = S.ProductKey

--The most selling brand
select Brand  , Sum (Unit_Price_USD * Quantity) As Reveneau
from Products P join Sales S
on P.ProductKey = S.ProductKey
group by Brand , Category
Order by Reveneau DESc

--The most selling brand
select  Distinct Category  , Sum (Unit_Price_USD * Quantity) As Reveneau
from Products P join Sales S
on P.ProductKey = S.ProductKey
group by  Category
Order by Reveneau DESC


-- Sales growth rate over years
SELECT 
    Year(Order_Date) As Year,
    Sum (Unit_Price_USD * Quantity) As TotalSales,
    CASE 
        WHEN LAG(COUNT(*)) OVER (ORDER BY  Year(Order_Date)) IS NOT NULL 
        THEN CONCAT(ROUND(((COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY  Year(Order_Date))) 
		/ CAST(LAG(COUNT(*)) OVER (ORDER BY  Year(Order_Date)) AS FLOAT)) * 100, 2), '%')
        ELSE '0%'
    END AS Yearly_Change_Percentage
FROM Sales S join Products P 
on s.ProductKey = P.ProductKey
GROUP BY  Year(Order_Date)
ORDER BY  Year(Order_Date);

-- Sales growth rate over months and years
WITH MonthlyCounts AS (
    SELECT
        FORMAT(Order_Date, 'yyyy-MM') AS Month,
        Sum (Unit_Price_USD * Quantity) As TotalSales
    FROM Sales S join Products P 
on S.ProductKey = P.ProductKey 
    GROUP BY FORMAT(Order_Date, 'yyyy-MM')
),
MonthlyLagged AS (
    SELECT
        Month,
        TotalSales,
        LAG(TotalSales) OVER (ORDER BY Month) AS PrevMonthAccidents
    FROM MonthlyCounts
)
SELECT 
    Month,
    TotalSales,
    CONCAT(CAST(ROUND(CASE 
                    WHEN PrevMonthAccidents IS NULL OR PrevMonthAccidents = 0 THEN 0
                    ELSE ((TotalSales - PrevMonthAccidents) * 100.0) / PrevMonthAccidents
                END, 
            2) AS float),'%') AS PercentageChange
FROM MonthlyLagged
ORDER BY Month;

-- Our 10 Distinguished Clients
select top 10 Name ,COUNT(Order_Number) AS PurchaseTimes , Sum (Unit_Price_USD * Quantity) As TotalSales
from Customers C 
join Products P
on c.CustomerKey = P.ProductKey 
join Sales S
on P.ProductKey = S.ProductKey
group by Name 
Order by PurchaseTimes DESC


--Countries sales
WITH SalesByCountry AS (
  SELECT 
    Country,Sum (Unit_Price_USD * Quantity) As TotalSales 
	FROM Customers C 
	join Sales S 
	on C.CustomerKey = S.CustomerKey 
	join Products P 
	on S.ProductKey = P.ProductKey
  GROUP BY Country
),
TotalSales AS (
  SELECT SUM(TotalSales) AS Total FROM SalesByCountry
)
SELECT 
  s.Country,
  s.TotalSales,
  FORMAT(s.TotalSales * 100.0 / t.Total, 'N2') + ' %' AS PercentOfTotal
FROM SalesByCountry s
CROSS JOIN TotalSales t
ORDER BY s.TotalSales DESC;

--Continent sales
WITH SalesByContinent AS (
  SELECT 
    Continent,Sum (Unit_Price_USD * Quantity) As TotalSales 
	FROM Customers C 
	join Sales S 
	on C.CustomerKey = S.CustomerKey 
	join Products P 
	on S.ProductKey = P.ProductKey
  GROUP BY Continent
),
TotalSales AS (
  SELECT SUM(TotalSales) AS Total FROM SalesByContinent
)
SELECT 
  s.Continent,
  s.TotalSales,
  FORMAT(s.TotalSales * 100.0 / t.Total, 'N2') + ' %' AS PercentOfTotal
FROM SalesByContinent s
CROSS JOIN TotalSales t
ORDER BY s.TotalSales DESC;

--Does the largest sales country have the largest number of branches?
select Country , count (State) As Count_of_Stores , Sum (Unit_Price_USD * Quantity) As TotalSales
from Stores S 
join Sales SA 
on S.StoreKey = SA.StoreKey
join Products P
on SA.ProductKey = P.ProductKey 
group by Country 
Order By TotalSales DESC

--Gender Sales

select
	Gender , COUNT (Order_Number) As No_of_Orders,Sum (Unit_Price_USD * Quantity) As TotalSales
from Customers C 
join Sales S
on C.CustomerKey = S.CustomerKey
join Products P
on S.ProductKey = S.ProductKey 
group by Gender 
order by TotalSales DESC


--Top 10 Products By Sales
Select top 10 Product_Name , Count (Order_Number) AS CountO_of_Orders , Sum (Unit_Price_USD * Quantity) As TotalSales
from Products P 
join Sales S 
on P.ProductKey = S.ProductKey
group by Product_Name
Order by CountO_of_Orders DESC


-- The opening date of each branch differs from the previous one in days
SELECT 
  Open_Date,
  ISNULL(DATEDIFF(DAY, LAG(Open_Date) OVER (ORDER BY Open_Date), Open_Date), 0) AS DaysFromPreviousStore,
  State,
  Country
FROM Stores
ORDER BY Open_Date;


--Average Sales
select Avg(Unit_Price_USD * Quantity) As AVGSales
from Sales S
join Products P
on S.ProductKey = P.ProductKey


--Stores that achieve less than average sales
WITH StoreSales AS (
  SELECT 
    State,
    Sum (Unit_Price_USD * Quantity) As TotalSales
  FROM Stores S 
  join Sales SA 
  on S.StoreKey = SA.StoreKey
  join Products P 
  on SA.ProductKey =P.ProductKey
  GROUP BY State
),
AverageProfit AS (
  SELECT AVG(TotalSales) AS AvgProfit FROM StoreSales
)
SELECT 
  s.State,
  s.TotalSales
FROM StoreSales s
CROSS JOIN AverageProfit a
WHERE s.TotalSales < a.AvgProfit;
