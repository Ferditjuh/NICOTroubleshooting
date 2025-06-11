function Invoke-SignCode {
    [CmdletBinding()]
    param (
        # The file path of the script to be signed
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    begin {
        # Retrieve the code signing certificate from the current user's certificate store
        # The certificate must have "Code Signing" in its Enhanced Key Usage List and must not be expired
        $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { 
            ($_.EnhancedKeyUsageList -like "*Code Signing*") -and ($_.NotAfter -gt (Get-Date)) 
        } | Select-Object -First 1

        # If no valid certificate is found, throw an error
        if (-not $cert) {
            throw "No valid code signing certificate found in the current user's certificate store."
        }
    }
    process {
        # Sign the script at the specified file path using the retrieved certificate
        # A timestamp server is used to ensure the signature remains valid even after the certificate expires
        Set-AuthenticodeSignature -FilePath $Path -Certificate $cert -TimestampServer "http://timestamp.digicert.com"
    }
    end {
        Write-Host
    }
}
