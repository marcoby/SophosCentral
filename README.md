# Sophos Central PowerShell Module

This is a collection on functions for working with the Sophos Central API.

It currently supports:

* Logging in using a Sophos Partner Service Principal and accessing customer tenants
* Logging in using a Service Principal created within a tenant itself (for Sophos Central Customers)
* Retrieving a list of Endpoints and their current status
* Invoking a scan on an Endpoint (or list of Endpoints)
* Retrieving a list of Alerts
* Action a list of Alerts
* Create a new user

This module is tested on PowerShell 7.1, it may work on Windows PowerShell 5. It will not work on Windows PowerShell 4 or earlier

## API Credentials/Service Principal

Sophos customers can connect to their tenant using a client id/secret. Follow Step 1 here to create it
<https://developer.sophos.com/getting-started-tenant>

Sophos partners can use a partner client id/secret to connect to their customer tenants. Follow Step 1 here to create it
<https://developer.sophos.com/getting-started>

## Saving Credentials

It is recommended to use a service such as Azure Key Vault to store the client id/secret. See [Azure Key Vault Example](./Examples/Azure%20Key%20Vault%20Example.md) for an example implementation

## Importing the module

If your cloning this repo using Git, import the module using one of the *.psm1 files in .\SophosCentral\

```pwsh
Import-Module .\SophosCentral\SophosCentral.psm1
```

If your downloading the 'SophosCentral.zip' from the releases, you can use the .psd1

```pwsh
Import-Module .\SophosCentral.psd1
```

This is due to me not updating the psd1 often enough in the repo. The copy in the releases zip files will have the correct entries in there, as it's automatically generated.

## Function Documentation

See <https://github.com/simon-r-watson/SophosCentral/wiki>. This is automatically updated after each release. Due to this, it may not be up to date for newly added or modified functions in the main branch of this repo.

## Examples

See [Examples](./Examples/) for further examples

### Connect to Sophos Central

* The Client Secret is set to a secure string, to make it harder for people to accidentally enter the secret into the PowerShell console in plain text (which ends up on disk in plain text due to the command history feature, and also in the transcription logging if that is enabled)

``` powershell
$ClientID = Read-Host -Prompt 'Client ID'
$ClientSecret = Read-Host -AsSecureString -Prompt 'Client Secret'
Connect-SophosCentral -ClientID $ClientID -ClientSecret $ClientSecret
```

### Get Alerts

``` powershell
$alerts = Get-SophosCentralAlert
```

### Enable Tamper Protection

``` powershell
Get-SophosCentralEndpoint | `
    Where-Object {$_.tamperprotectionenabled -ne $true} | `
        ForEach-Object { 
            Set-SophosCentralEndpointTamperProtection -EndpointID $_.id -Enabled $true -Force
        }
```

### Get Endpoints with Tamper Protection disabled

``` powershell
Get-SophosCentralEndpoint | `
    Where-Object {$_.tamperprotectionenabled -ne $true}
```

### Audit Customer Tenant Settings

See [AuditTenantSettings.ps1](./Examples/AuditTenantSettings.ps1)
