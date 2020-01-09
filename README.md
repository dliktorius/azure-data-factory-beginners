# Azure Data Factory for Beginners

This repository contains a PowerShell script and Azure Resource Manager (ARM) Template to support the demos from my talk, "Azure Data Factory for Beginners" presented to the Microsoft Data and AI User Group at the Microsoft LATAM office in Fort Lauderdale, FL.

## Getting Started
Please download the PowerShell script, ARM template and SQL script files into the same folder.  Optionally, upload the PowerShell script and ARM template into Azure CloudShell for ease of use.  Otherwise, when running locally you will need to first authenticate against Azure within PowerShell prior to running the script. 

__Disclaimers: The script requires editing, but has comments throughtout to guide you.  Niether I nor any associated party will be liable for any negative, unwanted or unexpected effects as a result of you downloading or running the scripts in this repository.__

__Note: Resources deployed within Microsoft Azure can and will incur costs you will be liable for.__

## PowerShell Environment Setup Script
The _setup-environment.ps1_ PowerShell script sets up an environment within your own Azure subscription as follows.

1. A SOURCE Azure SQL Database Server with a restored copy of Microsoft's Wide World Importers sample database found on GitHub
2. A DESTINATION Azure SQL Database Server
3. An Azure Data Factory instance

You may use the included _arm_template.zip_ file and Import it into Azure Data Factory to recreate the entire factory, with pipelines, datasets and linked services (datastore connections).

__Note: When importing the Data Factory ARM Template, you will be forced to specify Azure SQL Database connection strings and must provide values specific for YOUR environment.__
