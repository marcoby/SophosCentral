function Get-SophosCentralCustomerTenants {
    <#
    .SYNOPSIS
        List Sophos Central customer tenants that can be connected too (for Sophos partners only)
    .DESCRIPTION
        List Sophos Central customer tenants that can be connected too (for Sophos partners only)
        https://developer.sophos.com/getting-started
    .EXAMPLE
        Get-SophosCentralCustomerTenants
    #>
    if ($global:SophosCentral.IDType -ne 'partner') {
        throw "You are not currently logged in using a Sophos Central Partner Service Principal"
    }
    else {
        Write-Verbose "currently logged in using a Sophos Central Partner Service Principal"
    }

    try {
        $header = Get-SophosCentralAuthHeader -PartnerInitial
    }
    catch {
        throw $_
    }
    $uri = [System.Uri]::New('https://api.central.sophos.com/partner/v1/tenants?pageTotal=true')
    Invoke-SophosCentralWebRequest -Uri $uri -CustomHeader $header
}