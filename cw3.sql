CREATE PROCEDURE GetHistoricalCurrencyRates
    @YearsAgo INT
AS
BEGIN
    DECLARE @DateYearsAgo DATE;
    SET @DateYearsAgo = DATEADD(YEAR, -@YearsAgo, GETDATE());

    SELECT
        f.Date, 
        f.AverageRate, 
        f.EndOfDayRate, 
        f.CurrencyKey, 
        d.CurrencyAlternateKey
    FROM 
        AdventureWorksDW2019.dbo.FactCurrencyRate f
    INNER JOIN 
        AdventureWorksDW2019.dbo.DimCurrency d ON f.CurrencyKey = d.CurrencyKey
    WHERE 
        f.Date <= @DateYearsAgo
        AND d.CurrencyAlternateKey IN ('GBP', 'EUR')  
    ORDER BY 
        f.Date DESC;
END;
GO
EXEC GetHistoricalCurrencyRates @YearsAgo=12;