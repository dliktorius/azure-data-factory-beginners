-- Use this script at the DESTINATION
-- Sync by Date Demo

USE [DestinationDatabase]
GO

DROP TABLE IF EXISTS Watermarktable;
GO

-- Create the control/tracking table
CREATE TABLE WatermarkTable
(
	WatermarkValue datetime2(7)
);
GO

-- Starting value
INSERT INTO WatermarkTable
VALUES ('2001-01-01');
GO

DROP PROCEDURE IF EXISTS update_watermark;
GO

-- Create watermark update procedure
CREATE PROCEDURE update_watermark 
	@LastEditedWhen datetime2(7)
AS
BEGIN
 	UPDATE WatermarkTable
 	SET [WatermarkValue] = @LastEditedWhen
END;
GO

-- Create Final Destination Table
DROP TABLE IF EXISTS [Sales].[Orders]
GO

CREATE TABLE [Sales].[Orders](
	[OrderID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[ExpectedDeliveryDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsUndersupplyBackordered] [bit] NOT NULL,
	[Comments] [nvarchar](max) NULL,
	[DeliveryInstructions] [nvarchar](max) NULL,
	[InternalComments] [nvarchar](max) NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Sales_Orders] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

-- Drop/Create Staging Table Drop Procedure
DROP PROCEDURE IF EXISTS Drop_Staging_Sales_Orders;
GO

CREATE PROCEDURE Drop_Staging_Sales_Orders
AS
BEGIN
	DROP TABLE IF EXISTS Staging.Sales_Orders
END;

-- Drop/Crate Merge procedure - latest inserted or updated records into Sales.Orders
DROP TABLE IF EXISTS Staging.Sales_Orders;
GO
DROP PROCEDURE IF EXISTS Sales_Orders_Merge;
GO

CREATE PROCEDURE Sales_Orders_Merge
AS
BEGIN
	MERGE Sales.Orders AS [Target]
	USING Staging.Sales_Orders AS [Source]
	ON ([Target].OrderID = [Source].OrderId)
	WHEN MATCHED THEN
		UPDATE SET 
		   [CustomerID] = [Source].[CustomerID]
		  ,[SalespersonPersonID] = [Source].[SalespersonPersonID]
		  ,[PickedByPersonID] = [Source].[PickedByPersonID]
		  ,[ContactPersonID] = [Source].[ContactPersonID]
		  ,[BackorderOrderID] = [Source].[BackorderOrderID]
		  ,[OrderDate] = [Source].[OrderDate]
		  ,[ExpectedDeliveryDate] = [Source].[ExpectedDeliveryDate]
		  ,[CustomerPurchaseOrderNumber] = [Source].[CustomerPurchaseOrderNumber]
		  ,[IsUndersupplyBackordered] = [Source].[IsUndersupplyBackordered]
		  ,[Comments] = [Source].[Comments]
		  ,[DeliveryInstructions] = [Source].[DeliveryInstructions]
		  ,[InternalComments] = [Source].[InternalComments]
		  ,[PickingCompletedWhen] = [Source].[PickingCompletedWhen]
		  ,[LastEditedBy] = [Source].[LastEditedBy]
		  ,[LastEditedWhen] = [Source].[LastEditedWhen]
	WHEN NOT MATCHED THEN
		INSERT (
		   [OrderID]
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
		)
		VALUES( 
		   [Source].[OrderID]
		  ,[Source].[CustomerID]
		  ,[Source].[SalespersonPersonID]
		  ,[Source].[PickedByPersonID]
		  ,[Source].[ContactPersonID]
		  ,[Source].[BackorderOrderID]
		  ,[Source].[OrderDate]
		  ,[Source].[ExpectedDeliveryDate]
		  ,[Source].[CustomerPurchaseOrderNumber]
		  ,[Source].[IsUndersupplyBackordered]
		  ,[Source].[Comments]
		  ,[Source].[DeliveryInstructions]
		  ,[Source].[InternalComments]
		  ,[Source].[PickingCompletedWhen]
		  ,[Source].[LastEditedBy]
		  ,[Source].[LastEditedWhen]
		 );
END;
GO
