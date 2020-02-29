-- Use this script at the SOURCE
USE [SourceDatabase]
GO

SELECT TOP(1) MAX(OrderID) FROM Sales.Orders;

SELECT TOP (5) [OrderID]
      ,[Comments]
      ,[CustomerID]
      ,[SalespersonPersonID]
      ,[PickedByPersonID]
      ,[ContactPersonID]
      ,[BackorderOrderID]
      ,[OrderDate]
      ,[ExpectedDeliveryDate]
      ,[CustomerPurchaseOrderNumber]
      ,[IsUndersupplyBackordered]
      ,[DeliveryInstructions]
      ,[InternalComments]
      ,[PickingCompletedWhen]
      ,[LastEditedBy]
      ,[LastEditedWhen]
FROM [Sales].[Orders]
ORDER BY 1 DESC;

/*
INSERT INTO [Sales].[Orders] (
	   [CustomerID]
      ,[SalespersonPersonID]
      ,[PickedByPersonID]
      ,[ContactPersonID]
      ,[BackorderOrderID]
      ,[OrderDate]
      ,[ExpectedDeliveryDate]
      ,[CustomerPurchaseOrderNumber]
      ,[IsUndersupplyBackordered]
      ,[Comments]
      ,[DeliveryInstructions]
      ,[InternalComments]
      ,[PickingCompletedWhen]
      ,[LastEditedBy]
      ,[LastEditedWhen]
)
SELECT 
	   [CustomerID]
      ,[SalespersonPersonID]
      ,[PickedByPersonID]
      ,[ContactPersonID]
      ,[BackorderOrderID]
      ,GETDATE()
      ,DATEADD(d, 5, GETDATE())
      ,[CustomerPurchaseOrderNumber]
      ,[IsUndersupplyBackordered]
      ,'After lunch at SFSDC 2020'
      ,[DeliveryInstructions]
      ,[InternalComments]
      ,[PickingCompletedWhen]
      ,[LastEditedBy]
      ,[LastEditedWhen]
FROM
	[Sales].[Orders]
WHERE
	OrderID = 1;
*/

/*
-- Reset after Sync by Order ID Demo
DELETE FROM Sales.Orders
WHERE OrderID > 73595;
GO

ALTER SEQUENCE [Sequences].OrderID
    RESTART WITH 73596
    INCREMENT BY 1
    NO CYCLE
    NO CACHE;
GO
*/

/*
-- Sync by Date Demo
UPDATE Sales.Orders
SET
	[Comments] = 'Great day at SFSDC 2020',
	[LastEditedWhen] = GETDATE()
WHERE OrderID = 73592;
*/

/*
-- Reset after Sync By Date Demo
UPDATE Sales.Orders
SET
	[Comments] = NULL,
	[LastEditedWhen] = '2016-05-31 12:00:00.0000000'
WHERE OrderID = 73592;
*/