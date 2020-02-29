USE [DestinationDatabase]
GO

SELECT TOP (10) [OrderID]
	  ,[Comments]
      ,[CustomerID]
      ,[SalespersonPersonID]
      ,[PickedByPersonID]
      ,[ContactPersonID]
      ,[BackorderOrderID]
      ,[OrderDate] -- This column has the 'Mapped' suffix for the first Demo
      ,[ExpectedDeliveryDate]
      ,[CustomerPurchaseOrderNumber]
      ,[IsUndersupplyBackordered]
      ,[DeliveryInstructions]
      ,[InternalComments]
      ,[PickingCompletedWhen]
      ,[LastEditedBy]
      ,[LastEditedWhen]
  FROM [Sales].[Orders]
  ORDER BY OrderID DESC;

  /*
  -- Use this between demos
  USE [DestinationDatabase]
  GO
  DROP TABLE Sales.Orders;
  GO
  */