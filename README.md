# AdobeUMRunbook

## Synopsis
A Runbook to sync Azure AD Group with Adobe using a PowerShell Module framework (AdobeUM) for communicating with Adobe's User Management API

## Description
General Usage Instructions</br>
1. Create a service account and link it to your User Management binding. (Do this at Adobe's Console)
2. Create a PKI certificate. You can create a self signed one using the provided Import-PFXCert command
3. Export the PFX and a public certificate from your generated certificate.
4. Upload the public cert to the account you created in step 1.
5. Upload the private cert to the Automation Account that will run this runbook as a Certicate Asset
6. Using the information adobe gave you in step 1, add Variable assets to the Automation Account
    - APIKey
    - OrganizationID
    - ClientSecret
    - TechnicalAccountID
    - TechnicalAccountEmail
7. Create a RunAsAccount for the Automation Account and Give to access to the Read Directory Data using the Windows Azure AD API

## Parameters
- **AdobeGroup** - A string containing the name of the Adobe Group to Sync Federated Users from an Azure AD Group
- **ADGroup** - A string containing the name of the Azure AD to Sync Federated Users to an Adobe Group

## Prerequisites
- Azure Tenant 
- Azure Automation Account
- AzureAD Module 
- AdobeUM Module

## Versioning
[Github](http://github.com/) for version control.

## Authors
* **Paul Towler** - *Initial work* - [AdobeUMRunbook](https://github.com/mrptsai/AdobeUMRunbook)

See also the list of [contributors](https://github.com/mrptsai/AdobeUMRunbook/graphs/contributors) who participated in this project.
