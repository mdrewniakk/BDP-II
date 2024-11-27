DROP TABLE IF EXISTS AdventureWorksDW2019.dbo.stg_dimemp;

SELECT EMPLOYEEKEY, FIRSTNAME, LASTNAME, TITLE
INTO AdventureWorksDW2019.dbo.stg_dimemp
FROM AdventureWorksDW2019.dbo.DimEmployee
WHERE EMPLOYEEKEY BETWEEN 270 AND 275;

DROP TABLE IF EXISTS AdventureWorksDW2019.dbo.scd_dimemp;

CREATE TABLE AdventureWorksDW2019.dbo.scd_dimemp (
EmployeeKey int ,
FirstName nvarchar(50) not null,
LastName nvarchar(50) not null,
Title nvarchar(50),
StartDate datetime,
EndDate datetime);

INSERT INTO AdventureWorksDW2019.dbo.scd_dimemp (EmployeeKey, FirstName, LastName, Title, StartDate, EndDate)
SELECT EmployeeKey, FirstName, LastName, Title, StartDate, EndDate
FROM AdventureWorksDW2019.dbo.DimEmployee
WHERE EmployeeKey >= 270 AND EmployeeKey <= 275
--5b
--Typ 1: overwrite i 2: add new row
update AdventureWorksDW2019.dbo.stg_dimemp
set LastName = 'Nowak'
where EmployeeKey = 270;

update AdventureWorksDW2019.dbo.stg_dimemp
set TITLE = 'Senior Design Engineer'
where EmployeeKey = 274;--5c-- Typ 3: add new attributeupdate AdventureWorksDW2019.dbo.stg_dimemp
set FIRSTNAME = 'Ryszard'
where EmployeeKey = 275SELECT * FROM AdventureWorksDW2019.dbo.stg_dimemp

SELECT * FROM AdventureWorksDW2019.dbo.scd_dimemp


--Error: 0xC020803C at cw6, Slowly Changing Dimension [107]: If the FailOnFixedAttributeChange property is set to TRUE,
--the transformation will fail when a fixed attribute change is detected. To send rows to the Fixed Attribute output, 
--set the FailOnFixedAttributeChange property to FALSE.

--To ustawienie powoduje, ¿e transformacja koñczy siê niepowodzeniem, gdy wykryta zostanie zmiana w atrybucie sta³ym (atrybucie, który nie powinien ulegaæ zmianie).
