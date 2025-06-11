function Test-TIStatus {
    [CmdletBinding()]
    param (
        # The name of the remote computer to check the TrustedInstaller service status
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )

    begin {
        # Initialization code if needed
    }
    process {
        $scriptBlock = {
            do {
                try {
                    # Attempt to get the status of the TrustedInstaller service
                    $serviceStatus = (Get-Service TrustedInstaller -ErrorAction Stop).Status

                    if ($serviceStatus -eq 'Running') {
                        # If the service is running, wait for 30 seconds before checking again
                        Write-Host "TrustedInstaller is running, waiting 30s..."
                        Start-Sleep -Seconds 30
                    }
                }
                catch {
                    # Handle errors, such as if the service is not found or cannot be queried
                    Write-Error "Failed to query the TrustedInstaller service: $_"
                    break
                }
            } while ($serviceStatus -eq 'Running') # Continue checking until the service is no longer running

            # Output a message when the TrustedInstaller service is no longer running
            Write-Host "TrustedInstaller is no longer running."
        }

        # Execute the script block on the specified remote computer
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock
    }
    end {
        Write-Host
    }
}
