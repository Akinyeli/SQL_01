Select * from factors;
Select * from product;
Select * from sales;

--Q1 What is the total number of units sold per product SKU?
Select productid, sum(inventoryquantity) as total_units_sold
From sales
Group by (productid)
Order by  total_units_sold DESC;

--Q2 Which product category had the highest sales volume last month?
Select p.productcategory, sum(s.inventoryquantity) as sales_volume
From product p
Join sales s on p.productid=s.productid
where s.salesdate between '2022-11-01' and '2022-11-30'
Group by p.productcategory
Order by sales_volume DESC
Limit 1;

-- Q3 How does the inflation rate correlate with sales volume for a specific month?
Select s.sales_month, s.sales_year, round(avg(f.inflationrate),2) as Avg_inflation, sum(s.inventoryquantity) as sales_volume
From sales s
Join factors f on s.salesdate=f.salesdate
Group by s.sales_year, s.sales_month
Order by s.sales_year DESC, s.sales_month ASC;

-- Q4 What is the correlation between the inflation rate and sales quantity for all products combined on a monthly basis over the last year?
Select s.sales_month, s.sales_year, round(avg(f.inflationrate),2) as Avg_inflation, sum(s.inventoryquantity) as sales_volume
From sales s
Join factors f on s.salesdate=f.salesdate
where s.salesdate >= (CURRENT_DATE - INTERVAL '1 Year')
Group by s.sales_year, s.sales_month
Order by s.sales_year DESC, s.sales_month ASC;

--Q5 Did promotions significantly impact the sales quantity of products?
Select p.productcategory, p.promotions, round(avg(s.inventoryquantity), 2) as avg_sales
From product p
Join sales s on p.productid=s.productid
Group by p.productcategory, p.promotions;

--OR
Select p.productcategory, round(avg(s.inventoryquantity)) as avg_sales, p.promotions
From product p
Join sales s on p.productid=s.productid
Where p.promotions = 'No'
Group by p.productcategory, p.promotions

Union All

Select p.productcategory, round(avg(s.inventoryquantity)) as avg_sales, p.promotions
From product p
Join sales s on p.productid=s.productid
Where p.promotions = 'Yes'
Group by p.productcategory, p.promotions;

--Q6 What is the average sales quantity per product category?
Select p.productcategory, round(avg(s.inventoryquantity)) as Avg_sales_quantity
from product p
join sales s on p.productid=s.productid
Group by p.productcategory
Order by avg_sales_quantity DESC;

--Q7 How does the GDP affect the total sales volume?
Select s.sales_year, round(sum(f.gdp),2) as Total_GDP, sum(s.inventoryquantity) as sales_volume
From sales s
Join factors f on s.salesdate=f.salesdate
Group by s.sales_year
Order by sales_volume DESC;

--Q8 What are the top 10 best-selling product SKUs?
Select productid, sum(inventoryquantity) as Sales_volume
from sales
Group by productid
order by sales_volume DESC
limit 10;

--Q9 How do seasonal factors influence sales quantities for different product categories?
Select p.productcategory, round(avg(f.seasonalfactor), 4) as avg_seasonalfactor, sum(s.inventoryquantity) as total_quantity
From sales s
Join factors f on s.salesdate=f.salesdate
Join product p on p.productid=s.productid
Group by p.productcategory
Order by avg_seasonalfactor;

--Q10 What is the average sales quantity per product category, and how many products within each category were part of a promotion?
Select p.productcategory, round(avg(s.inventoryquantity)) as Avg_Quantity,
count(Case When p.promotions = 'Yes' Then 1 End) as No_of_Promotions
from product p
join sales s on p.productid=s.productid
Group by p.productcategory
Order by Avg_Quantity

--Sales Trend Over Months to show demand flunctuations
Select salesdate, inventoryquantity
From Sales

Select s.salesdate, s.productid, s.productcost, s.sales_year, s.inventoryquantity, p.productid, p.productcategory, f.seasonalfactor, f.inflationrate, f.gdp
From Sales s
Join factors f on s.salesdate=f.salesdate
Join product p on p.productid=s.productid

--Average sales and variance for each product to optimize stock levels
SELECT
    productid,
    AVG(inventoryquantity) AS Avg_Sales,
    STDDEV(inventoryquantity) AS Sales_Variance,
    MIN(salesdate) AS First_Sale_Date,
    MAX(salesdate) AS Last_Sale_Date
FROM sales
GROUP BY Productid;

--Monthly Sales Trends
SELECT Productid, sales_year, sales_month, SUM(inventoryquantity) AS Total_Sales
FROM Sales
GROUP BY Productid, sales_year, sales_month
ORDER BY Productid, Sales_Year, Sales_Month;

-- High Demands Periods
SELECT Productid, Sales_Year, Sales_Month, SUM(InventoryQuantity) AS Sales_Quantity
FROM Sales
GROUP BY Productid, Sales_year, sales_month
HAVING SUM(InventoryQuantity) = (SELECT MAX(InventoryQuantity)
                   FROM (SELECT Sales_Year, Sales_Month FROM Sales 
                   WHERE Productid = sales.Productid
                   GROUP BY Sales_Year, Sales_month) as Period)
ORDER BY Productid, Sales_Year, Sales_Month;

--Confirm stockout
SELECT
    s.Productid,
    f.Salesdate,
    f.SeasonalFactor,
    COALESCE(SUM(s.InventoryQuantity), 0) AS Total_Sales
FROM Factors f
LEFT JOIN sales s ON s.Salesdate = f.Salesdate
GROUP BY s.Productid,f.Salesdate, f.SeasonalFactor
HAVING COALESCE(SUM(s.InventoryQuantity), 0) = 0;

--Inventory Turnover Rate
SELECT Productid, Div(SUM(Inventoryquantity), Avg(InventoryQuantity)) as Inventory_Turnover
from Sales
Group by Productid
Order by Inventory_Turnover DESC;

SELECT 
    Productid, 
    Sales_Year, 
    Sales_Month, 
    SUM(InventoryQuantity) AS Sales_Quantity
FROM Sales
GROUP BY Productid, Sales_Year, Sales_Month
HAVING SUM(InventoryQuantity) = (
    SELECT MAX(Total_Sales)
    FROM (
        SELECT 
            Productid, 
            Sales_Year, 
            Sales_Month, 
            SUM(InventoryQuantity) AS Total_Sales
        FROM Sales
        GROUP BY Productid, Sales_Year, Sales_Month
    ) SubQuery
    WHERE SubQuery.Productid = Sales.Prod
