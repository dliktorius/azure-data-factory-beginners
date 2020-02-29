# Azure Data Factory for Beginners

This repository contains a PowerShell script and Azure Resource Manager (ARM) Template to support the demos from my talk, "Azure Data Factory for Beginners" presented to:
* Microsoft Data and AI User Group at the Microsoft LATAM office in Fort Lauderdale, FL.
* SQL Saturday #946 South Florida BI Edition (2020)
* South Florida Software Developers Conference 2020

## Getting Started
Please download the PowerShell script at a minimum.  It will use the ARM .json template file at the root of this repository to deploy the Azure Data Factory after deploying two Azure SQL Database instances (a source and a destination).  Optionally, upload the PowerShell script and ARM template into Azure CloudShell.  You will need to first authenticate against Azure when promopted while running the script. 

__Disclaimers: The script requires editing, but has comments throughtout to guide you.  Neither I nor any associated party will be liable for any negative, unwanted or unexpected effects as a result of you downloading or running the scripts in this repository.  Please review and understand what the script performs before executing it.__

__Note: Resources deployed within Microsoft Azure can and will incur costs you will be liable for.__

## PowerShell Environment Setup Script
The _setup-environment.ps1_ PowerShell script sets up an environment within your own Azure subscription as follows.

1. A SOURCE Azure SQL Database Server with a restored copy of Microsoft's Wide World Importers sample database found on GitHub
2. A DESTINATION Azure SQL Database Server
3. An Azure Data Factory instance

## Azure Data Factory ARM Template
The script will use the ARM template in this repository by default, but you may alternatively use the included _arm_template.zip_ file and Import it into Azure Data Factory to recreate the entire factory, with pipelines, datasets and linked services (datastore connections).

__Note: When importing the Data Factory ARM Template, you will be forced to specify Azure SQL Database connection strings and must provide values specific for YOUR environment.  If you allow the script to create the factory, it will supply the connection strings and credentials__  You can obtain a sample connection string for each Azure SQL Database from the Connection Strings blade within the Azure Portal for said database server.

## SQL Scripts
* __Sales Orders Queries.sql__ contains queries used during the demo for the SOURCE database.
* __Sales Orders Destination Queries.sql__ contains queries used during the demo for the DESTINATION database.
* __DeltaSyncDemo.sql__ contains statements used to create the table and stored procedure used by the _DeltaSyncPipeline_.
* __DeltaSyncByDateDemo.sql__ contains statements used to create the table and stored procedure used by the _DeltaSyncByDatePipeline_.
