SELECT OrderDate, Orders_cnt, EnglishProductName
FROM (
    SELECT OrderDate, 
        COUNT(OrderQuantity) OVER(PARTITION BY OrderDate) AS Orders_cnt,
		EnglishProductName,
        ROW_NUMBER() OVER (PARTITION BY OrderDate ORDER BY UnitPrice DESC, EnglishProductName deSC) AS RankWithinDate
    FROM DBO.FactInternetSales as Sales JOIN dbo.DimProduct as Prod ON Sales.ProductKey = Prod.ProductKey 
) AS sub
WHERE Orders_cnt < 100 AND RankWithinDate <=3
ORDER BY Orders_cnt DESC, OrderDate;


--a)
SELECT DISTINCT OrderDate, Orders_cnt
FROM (
    SELECT OrderDate, 
        COUNT(OrderQuantity) OVER(PARTITION BY OrderDate) AS Orders_cnt
    FROM DBO.FactInternetSales
) AS sub
WHERE Orders_cnt < 100
ORDER BY Orders_cnt DESC, OrderDate;
--b)
SELECT OrderDate, EnglishProductName
FROM (
    SELECT OrderDate, 
	EnglishProductName,
        ROW_NUMBER() OVER (PARTITION BY OrderDate ORDER BY UnitPrice DESC, EnglishProductName deSC) AS Rank
    FROM DBO.FactInternetSales as Sales JOIN dbo.DimProduct as Prod ON Sales.ProductKey = Prod.ProductKey 
) AS sub
WHERE Rank <=3;
