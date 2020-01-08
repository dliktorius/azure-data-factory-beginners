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

-- Create watermark update procedure
CREATE PROCEDURE update_watermark 
	@OrderID int
AS
BEGIN
 	UPDATE WatermarkTable
 	SET [WatermarkValue] = @OrderID 
END;
GO
