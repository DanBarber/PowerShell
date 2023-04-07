# Azure Automation #
Collection of scripts for automating tasks in Azure

## Scripts
* [Add-AzureUsers.ps1](#markdown-header-Add-AzureUsers.ps1) - *Bulk add users to AzureAD*
* [Add-AzureUsersToGroups.ps1](#markdown-header-AddAzureUsersToGroups.ps1) - *Bulk assign users to AzureAD groups*

## Prerequisites
* Ensure you have the [AzureAD](https://www.powershellgallery.com/packages/AzureAD) module installed.
* Ensure you run `Connect-AzAccount` before running any of the scripts.

## Add-AzureUsers.ps1
The script will add all users within the .csv to Azure AD.
Example csv template - [AddUsersToAzureADTemplate.csv](https://github.com/DanBarber/PowerShell/Azure/AddUsersToAzureADTemplate.csv)

## AddAzureUsersToGroups.ps1
The script will assign the ObjectId (ID of the Active Directory resource) to every Group ObjectID listed within the GroupObjectID field. All group ObjectIDs should be delimited with a semi-colon ';'.

Example csv template - [AddUsersToAzureADTemplate.csv](https://github.com/DanBarber/PowerShell/Azure/AddUsersToADGroupsTemplate.csv)