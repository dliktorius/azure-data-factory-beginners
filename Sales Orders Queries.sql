SELECT TOP(1) MAX(OrderID) FROM Sales.Orders;

SELECT TOP (5) [OrderID]
      ,[CustomerID]
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
FROM [Sales].[Orders]
ORDER BY 1 DESC;

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
      ,'Just created for user group'
      ,[DeliveryInstructions]
      ,[InternalComments]
      ,[PickingCompletedWhen]
      ,[LastEditedBy]
      ,[LastEditedWhen]
FROM
	[Sales].[Orders]
WHERE
	OrderID = 1;
