# https://docs.microsoft.com/en-us/azure/sql-database/scripts/sql-database-import-from-bacpac-powershell
# https://github.com/microsoft/sql-server-samples

# Run the following command if NOT running within Azure CloudShell and authenticate
# Connect-AzAccount
#
# REQUIRED: Provide values for these:
# The SubscriptionId in which to create these objects
$SubscriptionId = ""
# Set the resource group name and location for the resources
$resourceGroupName = "datafactory-demo-rg"
$location = "eastus"
# The storage account name - Name MUST be Globally Unique
$storageAccountName = "sqlimport$(Get-Random)"
# The container name within the storage account
$storageContainerName = "importcontainer"
# Set source server name - Name MUST be Globally Unique
$sourceServerName = "azsqlsourceserver$(Get-Random)"
# Set destination server name - Name MUST be Globally Unique
$destinationServerName = "azsqldestinationserver$(Get-Random)"
# Set the data factory resource name - Name MUST be Globally Unique
$dataFactoryName = "azdatafactory$(Get-Random)"
# Set an admin login and password for the Azure SQL Database Servers
$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
#
# The source database name
$sourceDatabaseName = "SourceDatabase"
# The destination database name
$destinationDatabaseName = "DestinationDatabase"
# The ip address range that you want to allow to access your server
$startip = "0.0.0.0"
$endip = "0.0.0.0"
# Get current working directory path
$currentWorkingDir = Get-Location
# BACPAC file name
$bacpacFilename = "sample.bacpac"
$bacpacFilePath = Join-Path $currentWorkingDir $bacpacFilename

# Deployment details
Write-Host "Deployment details"
Write-Host "=================="
Write-Host "Resource Group: $resourceGroupName"
Write-Host "Azure Region: $location"
Write-Host "Staging Azure Storage Account: $storageAccountName"
Write-Host "Staging Azure Storage Container: $storageContainerName"
Write-Host "Source Azure SQL Server: $sourceServerName"
Write-Host "Source Azure SQL Database: $sourceDatabaseName"
Write-Host "Destination Azure SQL Server: $destinationServerName"
Write-Host "Destination Azure SQL Database: $destinationDatabaseName"
Write-Host ""

# Set subscription 
Write-Host "Setting to Azure Subscription $subscriptionId"
Set-AzContext -SubscriptionId $subscriptionId 

# Create a resource group if it does not exist
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -Location $location -ErrorAction "silentlycontinue"
if(!$resourceGroup) {
	Write-Host "Azure Resource Group does not exist - Creating..."
	$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location
}
Write-Host "Resource Group"
Write-Host "=============="
$resourceGroup

# Create a storage account if it does not exist
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction "silentlycontinue"
if(!$storageAccount) {
	Write-Host "Azure Storage Account does not exist - Creating..."
	$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName `
		-AccountName $storageAccountName `
		-Location $location `
		-Type "Standard_LRS"
}
Write-Host "Storage Account"
Write-Host "==============="
$storageAccount

# Get storage context
Write-Host "Getting Storage Account Key and Context..."
$storageAccountKey = $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName).Value[0]
$storageContext = $(New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey)

# Create a storage container if one does not exist
$storageContainer = Get-AzStorageContainer -Name $storageContainerName -Context $storageContext -ErrorAction "silentlycontinue"
if(!$storageContainer) {
	Write-Host "Azure Blob Storage Container does not exist - Creating..."
	$storageContainer = New-AzStorageContainer -Name $storageContainerName -Context $storageContext
}
Write-Host "Storage Container"
Write-Host "================="
$storageContainer

# Download sample database from Github if one does not exist locally
if(![System.IO.File]::Exists($bacpacFilePath)){
    Write-Host "Sample database BACPAC file does not exist in local path - Downloading from GitHub..."
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 #required by Github
	Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac" -OutFile $bacpacFilePath
	Write-Host "Finished downloading BACPAC file!"
	Write-Host ""
}

# Upload sample database into storage container, if it does not exist in the container
$blobs = Get-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $bacpacFilename -ErrorAction "silentlycontinue"
if($blobs.Count -le 0) {
	Write-Host "BACPAC file does not exist in Azure Blob Storage Container - Uploading..."
	Set-AzStorageBlobContent -Container $storagecontainername `
		-File $bacpacFilePath `
		-Context $storageContext
	Write-Host "Uploaded BACPAC file to Azure Storage!"
	Write-Host ""
}

# Create a new SOURCE server with a system wide unique server name
$server = Get-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $sourceServerName -ErrorAction "silentlycontinue"
if(!$server) {
	Write-Host "SOURCE Azure SQL Database Server does not exist - Creating..."
	$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
		-ServerName $sourceServerName `
		-Location $location `
		-SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
		
	Write-Host "Azure SQL Database Server"
	Write-Host "========================="
	$server
	
	# Create a server firewall rule that allows access from the specified IP range
	$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
		-ServerName $sourceServerName `
		-FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp
}
	
# Create a new DESTINATION server with a system wide unique server name
$server = Get-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $destinationServerName -ErrorAction "silentlycontinue"
if(!$server) {
	Write-Host "DESTINATION Azure SQL Database Server does not exist - Creating..."
	$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
		-ServerName $destinationServerName `
		-Location $location `
		-SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

	Write-Host "Azure SQL Database Server"
	Write-Host "========================="
	$server
		
	# Create a server firewall rule that allows access from the specified IP range
	$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
		-ServerName $destinationServerName `
		-FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp
}

$sourceDatabase = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $sourceServerName -DatabaseName $sourceDatabaseName -ErrorAction "silentlycontinue"
if(!$sourceDatabase) {
	Write-Host "SOURCE Azure SQL Database does not exist - Import the BACPAC file from Azure Blob Storage..."
	# Import bacpac to database with an S4 performance level to speed this up
	$importRequest = New-AzSqlDatabaseImport -ResourceGroupName $resourceGroupName `
		-ServerName $sourceServerName `
		-DatabaseName $sourceDatabaseName `
		-DatabaseMaxSizeBytes "262144000" `
		-StorageKeyType "StorageAccessKey" `
		-StorageKey $storageAccountKey `
		-StorageUri "https://$storageaccountname.blob.core.windows.net/$storageContainerName/$bacpacFilename" `
		-Edition "Standard" `
		-ServiceObjectiveName "S4" `
		-AdministratorLogin "$adminSqlLogin" `
		-AdministratorLoginPassword $(ConvertTo-SecureString -String $password -AsPlainText -Force)
		
	# Check import status and wait for the import to complete
	$importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
	Write-Host "Importing"
	while ($importStatus.Status -eq "InProgress")
	{
		$importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
		Write-Host "." -NoNewline
		Start-Sleep -s 10
	}
	Write-Host ""
	Write-Host $importStatus
	
	# Scale down SOURCE server to S0 after import is complete
	Write-Host "Scaling down SOURCE Azure SQL Database to 'S0' size..."
	$sourceDatabase = Set-AzSqlDatabase -ResourceGroupName $resourceGroupName `
		-ServerName $sourceServerName `
		-DatabaseName $sourceDatabaseName  `
		-Edition "Standard" `
		-RequestedServiceObjectiveName "S0"
		
	Write-Host "Database SKU (objective): $sourceDatabase.SkuName ($sourceDatabase.CurrentServiceObjectiveName)"
	Write-Host ""
}

$destinationDatabase = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $destinationServerName -DatabaseName $destinationDatabaseName -ErrorAction "silentlycontinue"
if(!$destinationDatabase) {
	Write-Host "DESTINATION Azure SQL Database does not exist - Creating empty database..."
	$destinationDatabase = New-AzSqlDatabase -ResourceGroupName $resourceGroupName `
		-ServerName $destinationServerName `
		-DatabaseName $destinationDatabaseName `
		-Edition "Standard" `
		-RequestedServiceObjectiveName "S0"
		
	Write-Host "Database SKU (objective): Standard (S0)"
	Write-Host ""
}

$dataFactory = $DataFactory = Get-AzDataFactory -ResourceGroupName $resourceGroupName -Name $dataFactoryName -ErrorAction "silentlycontinue"
if(!$dataFactory) {
	Write-Host "Azure Data Factory does not exist - Creating new data factory..."
	$dataFactory = Set-AzDataFactoryV2 -ResourceGroupName $resourceGroupName `
		-Location $location -Name $dataFactoryName
		
	Write-Host $dataFactory
}


Write-Host "Finished!"

# Remove deployment 
# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName