-- Use this script at the DESTINATION
-- Sync by Order ID Demo

USE [DestinationDatabase]
GO

DROP TABLE IF EXISTS Watermarktable;
GO

-- Create the control/tracking table
CREATE TABLE WatermarkTable
(
	WatermarkValue int
);
GO

-- Starting value
INSERT INTO WatermarkTable
VALUES (0);
GO

DROP PROCEDURE IF EXISTS update_watermark;
GO

-- Create watermark update procedure
CREATE PROCEDURE update_watermark 
	@OrderID int
AS
BEGIN
 	UPDATE WatermarkTable
 	SET [WatermarkValue] = @OrderID 
END;
GO
