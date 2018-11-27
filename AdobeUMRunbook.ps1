#Requires -Modules AzureAD
#Requires -Modules AdobeUM.AzureAD
<#
.SYNOPSIS
    A Runbook to sync Azure AD Group with Adobe using a PowerShell Module framework (AdobeUM) for communicating with Adobe's User Management API

.DESCRIPTION
    General Usage Instructions
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

.PARAMETER AdobeGroup
    A string containing the name of the Adobe Group to Sync Federated Users from an Azure AD Group

.PARAMETER ADGroup
    A string containing the name of the Azure AD to Sync Federated Users to an Adobe Group

.NOTES
    Version:				0.01
    Author:		            Paul Towler  (Data#3)
    Creation Date:			8/11/2018 16:00
    Purpose/Change:			Initial script development
    Required Modules:       AzureAD, AdobeUM
    Dependencies:			Azure
    Limitations:            none
    Supported Platforms*:   Azure
                            *Currently not tested against other platforms
    Version History:        [8/11/2018 - 0.01 - Paul Towler]:   Initial Script
#>

param
(   
    [Parameter(Mandatory = $true)]
    [String]$AzureConnectionName,

    [parameter(Mandatory=$true)]
    [string]$AdobeGroup,

    [parameter(Mandatory=$true)] 
    [string]$ADGroup
)

#region Main Code
try
{
    Write-Output "Getting the connection 'AzureRunAsConnection'..."
    $servicePrincipalConnection = Get-AutomationConnection -Name $AzureConnectionName

    Write-Output "Getting the connection Variable Assets..."
    $APIKey = Get-AutomationVariable -Name 'APIKey'
    $OrganizationID = Get-AutomationVariable -Name 'OrganizationID'
    $ClientSecret = Get-AutomationVariable -Name 'ClientSecret'
    $TechnicalAccountID = Get-AutomationVariable -Name 'TechnicalAccountID'
    $TechnicalAccountEmail = Get-AutomationVariable -Name 'TechnicalAccountEmail'

    Write-Output "Getting the Adobe Certificate Asset..."
    $SignatureCert = Get-AutomationCertificate -Name 'AdobeAuthCertificate'
   
    Write-Output "Logging in to Azure AD..."
    Connect-AzureAD `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    Write-Output "Creating Client Information to connect to Adobe..."
    $ClientInformation = New-ClientInformation `
        -APIKey $APIKey `
        -OrganizationID $OrganizationID `
        -ClientSecret $ClientSecret `
        -TechnicalAccountID $TechnicalAccountID `
        -TechnicalAccountEmail $TechnicalAccountEmail

    Write-Output "Getting Auth Token to perform Adobe queries. (Is placed in ClientInformation variable)..."
    Get-AdobeAuthToken -ClientInformation $ClientInformation -SignatureCert $SignatureCert

    Write-Output "Getting ID for Adobe Synced Group..."
    $AdobeGroupId = Get-AdobeGroups -ClientInformation $ClientInformation | Where-Object name -eq $AdobeGroup | Select -ExpandProperty id
    
    Write-Output "Comparing Adobe and AD Groups to create/add/remove changes..."
    $Request = New-SyncADGroupRequest `
        -ADGroupID $ADGroup `
        -AdobeGroupID $AdobeGroupId `
        -ClientInformation $ClientInformation

    if ($Request)
    {
        Write-Output "Sending the generated request to Adobe..."
        Send-UserManagementRequest `
            -ClientInformation $ClientInformation `
            -Requests $Request
    } else
    {
        Write-Output "No changes to sync"
    }
} catch
{
    if($_.Exception.Message)
    {
        Write-Error -Message "$($_.Exception.Message)" -ErrorAction Continue
    }
    else
    {
        Write-Error -Message "$($_.Exception)" -ErrorAction Continue
    }
    throw "$($_.Exception)"
} finally
{
    Write-Output "Runbook ended at time: $(get-Date -format r)"
}
#endregion