# MIT License
# Copyright (c) 2020 Darius Liktorius
# https://liktorius.com
#
# Purpose:
#   To automatically deploy a fully-functioning environment in Azure consisting of:
#   1. Source Azure SQL Server with a restored copy of Microsoft's WideWorldImporters-Standard sample database
#   2. Destination Azure SQL Server with a restored copy of this project's destination sample database
#   3. An Azure Data Factory V2 instance
#   4. Azure Storage Account to hold the database bacpac (backup) files in order to restore them
#
# Notes:
#   1. This script should be run within PowerShell on a computer, *not* within Azure Cloud Shell or it will time-out
#   2. You MUST supply a valid Azure Subscription Id (Guid) in the $SubscriptionId variable below
#
# Repository: https://github.com/dliktorius/azure-data-factory-beginners
#
# https://docs.microsoft.com/en-us/azure/sql-database/scripts/sql-database-import-from-bacpac-powershell
# https://github.com/microsoft/sql-server-samples
#

# The SubscriptionId in which to create these objects
$SubscriptionId = ""
# Set the resource group name and location for the resources
$resourceGroupName = "demos-data-factory-rg"
# Set the Azure Region to deploy this demo solution to
$location = "centralus"
# Set an admin login and password for the Azure SQL Database Servers
$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
#
$skipResourceProviderChecks = $True

# Install the latest Azure PowerShell module (Az) for the current user scope if not already installed
# See: https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-3.5.0
#
# If you do not already have this installed, please UNCOMMENT the next line:
# Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Import the Azure 'Az' PowerShell module to make use of it
Import-Module Az

# Confirm SubscriptionId was supplied
if ([System.String]::IsNullOrEmpty($SubscriptionId)) {
	Write-Host 'The $SubscriptionId variable at the beginning of this script must be set to a valid subscription GUID' -ForegroundColor Red
	Break
}

# Establish Azure authentication context
$context = Get-AzContext
if (!$context)
{
	Connect-AzAccount
}

# Set subscription 
Write-Host "Setting to Azure Subscription $subscriptionId"
Set-AzContext -SubscriptionId $subscriptionId -WarningAction "Stop" -ErrorAction "Stop"
Write-Host ""

# Get current working directory path
$currentWorkingDir = Get-Location

# Check for and load-in or create random identifier from local file for subsequent executions
$configFilePath = Join-Path $currentWorkingDir "setup-environment.cfg"
if(![System.IO.File]::Exists($configFilePath)){
	$resourceGuid = $(New-Guid).ToString().split('-')[4]
	$resourceGuid | Out-File -FilePath $configFilePath
} else {
	$resourceGuid = Get-Content -Path $configFilePath -First 1
}

# The storage account name - Name MUST be Globally Unique
$storageAccountName = "adfdemostore$($script:resourceGuid)"
# The container name within the storage account
$storageContainerName = "importcontainer"
# Set source server name - Name MUST be Globally Unique
$sourceServerName = "adfdemosourceserver$($script:resourceGuid)"
# Set destination server name - Name MUST be Globally Unique
$destinationServerName = "adfdemodestinationserver$($script:resourceGuid)"
# Set the data factory resource name - Name MUST be Globally Unique
$dataFactoryName = "adfdemofactory$($script:resourceGuid)"
# The source database name
$sourceDatabaseName = "SourceDatabase"
# The destination database name
$destinationDatabaseName = "DestinationDatabase"
# The ip address range that you want to allow to access your server - CAUTION: Allowing all by default
$startip = "1.1.1.1"
$endip = "255.255.255.255"

# BACPAC file name and path
$bacpacFilename = "sample.bacpac"
$bacpacFilePath = Join-Path $currentWorkingDir $bacpacFilename
# Data Factory ARM template file name and path
$dataFactoryArmTemplateFilename = "arm_template.json"
$dataFactoryArmTemplateFilePath = Join-Path $currentWorkingDir $dataFactoryArmTemplateFilename
# Data Factory ARM Template Parameters
$dataFactoryARMtemplateUrl = "https://raw.githubusercontent.com/dliktorius/azure-data-factory-beginners/master/arm_template.json"
$dataFactoryARMparameters = @{
	factoryName = "$dataFactoryName"
	AzureSqlSourceDatabase_connectionString = "Server=tcp:$sourceServerName.database.windows.net,1433;Database=$sourceDatabaseName;User ID=SqlAdmin;Password=$password;Trusted_Connection=False;Encrypt=True;Connection Timeout=30"
	AzureSqlDestinationDatabase_connectionString = "Server=tcp:$destinationServerName.database.windows.net,1433;Database=$destinationDatabaseName;User ID=SqlAdmin;Password=$password;Trusted_Connection=False;Encrypt=True;Connection Timeout=30"
}

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

if(!$skipResourceProviderChecks) {
	Write-Host "Checking for required Resource Providers in this subscription..."

	# Register resource providers for Azure SQL Database and Azure Data Factory
	try 
	{	
		Register-AzResourceProvider -ProviderNamespace "Microsoft.Sql" -WarningAction "Stop" -ErrorAction "Stop"
		Register-AzResourceProvider -ProviderNamespace "Microsoft.DataFactory" -WarningAction "Stop" -ErrorAction "Stop"
	}
	catch [Microsoft.Rest.Azure.CloudException]
	{
		Write-Host 'The following error occurred while calling Register-AzResourceProvider.' `
			'Do you have Contributor or Owner rights over this subscription? If not, please communicate with your' `
			'subscription administrator(s) and request the Microsoft.Sql and Microsoft.DataFactory ''Resource Providers'' to' `
			'be registered for this subscription, then change the setting $skipResourceProviderChecks at the beginning of' `
			'this script to $True' -ForegroundColor Yellow
		Write-Host ""
		Write-Host $_.Exception.Message -ForegroundColor Red
		Write-Host ""
		Break
	}

	# loop up to 360 times with 10 second waits in-between (up to one hour) waiting for resource registration
	for ($i = 0; $i -lt 360; $i++)
	{
		Write-Host "Checking if resource providers have completed registering [$($i+1) of 360]... " -NoNewLine

		$providers = Get-AzResourceProvider -ProviderNamespace "Microsoft.Sql" -Location $location
		$providers = Get-AzResourceProvider -ProviderNamespace "Microsoft.DataFactory" -Location $location

		$finished = $true

		forEach($item in $providers)
		{
			if($item.RegistrationState -ne "Registered") {
				$finished = $false
				Write-Host "Not Yet! (Sleeping for 10 seconds...)" -ForegroundColor "Yellow"
				Break
			}
		}

		if($finished -eq $true) {
			Write-Host "Finished!" -ForegroundColor "Green"
			Break
		}

		Start-Sleep -Seconds 10
	}
}

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

# Download sample SOURCE database from Github if one does not exist locally
if(![System.IO.File]::Exists($bacpacFilePath)){
    Write-Host "Sample database BACPAC file does not exist in local path - Downloading from GitHub..."
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 #required by Github
	Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac" -OutFile $bacpacFilePath
	Write-Host "Finished downloading BACPAC file!"
	Write-Host ""
}

# Upload sample SOURCE database into storage container, if it does not exist in the container
$blobs = Get-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $bacpacFilename -ErrorAction "silentlycontinue"
if($blobs.Count -le 0) {
	Write-Host "BACPAC file does not exist in Azure Blob Storage Container - Uploading..."
	Set-AzStorageBlobContent -Container $storagecontainername `
		-File $bacpacFilePath `
		-Context $storageContext
	Write-Progress -Completed close
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
			
	# Create a server firewall rule that allows access from Azure services and the specified IP range
	$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
		-ServerName $sourceServerName -AllowAllAzureIPs
	
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

	# Create a server firewall rule that allows access from Azure services and the specified IP range
	$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
		-ServerName $destinationServerName -AllowAllAzureIPs
		
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
		Start-Sleep -s 5
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

$dataFactory = Get-AzDataFactory -ResourceGroupName $resourceGroupName -Name $dataFactoryName -ErrorAction "silentlycontinue"
if(!$dataFactory) {
	Write-Host "Azure Data Factory does not exist - Creating new data factory..."
	$dataFactory = Set-AzDataFactoryV2 -ResourceGroupName $resourceGroupName `
		-Location $location -Name $dataFactoryName
		
	Write-Host $dataFactory
}

if(![System.IO.File]::Exists($dataFactoryArmTemplateFilePath)){
	Write-Host "ARM template does not exist in local path - Downloading from GitHub..."
	Write-Host $dataFactoryARMtemplateUrl
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 #required by Github
	Invoke-WebRequest -Uri $dataFactoryARMtemplateUrl -OutFile $dataFactoryArmTemplateFilePath
	Write-Host "Finished downloading ARM template!"
	Write-Host ""
}

Write-Host "Updating Data Factory using ARM template..."
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $dataFactoryArmTemplateFilePath -TemplateParameterObject $dataFactoryARMparameters

Write-Host "Finished!"
