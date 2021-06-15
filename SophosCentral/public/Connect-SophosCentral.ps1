function Connect-SophosCentral {
    <#
    .SYNOPSIS
        Connect to Sophos Central using your client ID and client secret, from you API credentials/service principal
    .DESCRIPTION
        Connect to Sophos Central using your client ID and client secret, from you API credentials/service principal

        Sophos customers can connect to their tenant using a client id/secret. Follow Step 1 here to create it
        https://developer.sophos.com/getting-started-tenant

        Sophos partners can use a partner client id/secret here to connect to the customers. Follow Step 1 here to create it
        https://developer.sophos.com/getting-started
    .PARAMETER ClientID
        The client ID from the Sophos Central API credential/service principal
    .PARAMETER ClientSecret
        The client secret from the Sophos Central API credential/service principal
    .PARAMETER AzKeyVault
        Login using client ID and client secret stored in Azure Key Vault. Must be setup as explained in https://github.com/simon-r-watson/SophosCentral/wiki/AzureKeyVaultExample
    .PARAMETER AccessTokenOnly
        Internal use (for this module) only. Used to generate a new access token when the current one expires
    .EXAMPLE
        Connect-SophosCentral -ClientID "asdkjsdfksjdf" -ClientSecret (Read-Host -AsSecureString -Prompt "Client Secret:")
    .EXAMPLE
        Connect-SophosCentral -AzKeyVault
    .LINK
        https://developer.sophos.com/getting-started-tenant
    .LINK
        https://developer.sophos.com/getting-started
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ParameterSetName = 'StdAuth')]
        [String]$ClientID,

        [Parameter(ParameterSetName = 'StdAuth')]
        [SecureString]$ClientSecret,
        
        [Parameter(ParameterSetName = 'StdAuth')]
        [Switch]$AccessTokenOnly,

        [Parameter(ParameterSetName = 'AzKeyVaultAuth')]
        [Switch]$AzKeyVault
    )

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Warning 'Unsupported version of PowerShell detected'
    }

    if ($PsCmdlet.ParameterSetName -eq 'StdAuth') {
        if ($null -eq $ClientSecret) {
            $ClientSecret = Read-Host -AsSecureString -Prompt 'Client Secret:'
        }

        $loginUri = [System.Uri]::new('https://id.sophos.com/api/v2/oauth2/token')

        $body = @{
            grant_type    = 'client_credentials'
            client_id     = $ClientID
            client_secret = Unprotect-Secret -Secret $ClientSecret
            scope         = 'token'
        }
        try {
            $response = Invoke-WebRequest -Uri $loginUri -Body $body -ContentType 'application/x-www-form-urlencoded' -Method Post -UseBasicParsing
        } catch {
            throw "Error requesting access token: $($_)"
        }
    
        if ($response.Content) {
            $authDetails = $response.Content | ConvertFrom-Json
            $expiresAt = (Get-Date).AddSeconds($authDetails.expires_in - 60)

            if ($AccessTokenOnly -eq $true) {
                $GLOBAL:SophosCentral.access_token = $authDetails.access_token | ConvertTo-SecureString -AsPlainText -Force
                $GLOBAL:SophosCentral.expires_at = $expiresAt
            } else {
                $authDetails | Add-Member -MemberType NoteProperty -Name expires_at -Value $expiresAt
                $authDetails.access_token = $authDetails.access_token | ConvertTo-SecureString -AsPlainText -Force
                $GLOBAL:SophosCentral = $authDetails

                $tenantInfo = Get-SophosCentralTenantInfo
                $GLOBAL:SophosCentral | Add-Member -MemberType NoteProperty -Name GlobalEndpoint -Value $tenantInfo.apiHosts.global
                $GLOBAL:SophosCentral | Add-Member -MemberType NoteProperty -Name RegionEndpoint -Value $tenantInfo.apiHosts.dataRegion
                $GLOBAL:SophosCentral | Add-Member -MemberType NoteProperty -Name TenantID -Value $tenantInfo.id
                $GLOBAL:SophosCentral | Add-Member -MemberType NoteProperty -Name IDType -Value $tenantInfo.idType

                $GLOBAL:SophosCentral | Add-Member -MemberType NoteProperty -Name client_id -Value $ClientID
                $GLOBAL:SophosCentral | Add-Member -MemberType NoteProperty -Name client_secret -Value $ClientSecret
            }
        }
    } elseif ($PsCmdlet.ParameterSetName -eq 'AzKeyVaultAuth') {
        try { 
            Connect-AzAccount 
        } catch {
            throw 'Error connecting to Azure PowerShell'
        }
        try {
            #try twice, as sometimes the call silently fails
            $clientID = Get-Secret 'SophosCentral-Partner-ClientID' -Vault AzKV -AsPlainText
            $clientSecret = Get-Secret -Name 'SophosCentral-Partner-ClientSecret' -Vault AzKV

            $clientID = Get-Secret 'SophosCentral-Partner-ClientID' -Vault AzKV -AsPlainText
            $clientSecret = Get-Secret -Name 'SophosCentral-Partner-ClientSecret' -Vault AzKV
        } catch {
            throw "Error retrieving secrets from Azure Key Vault: $_"
        }
        
        Connect-SophosCentral -ClientID $clientID -ClientSecret $clientSecret
    }
}