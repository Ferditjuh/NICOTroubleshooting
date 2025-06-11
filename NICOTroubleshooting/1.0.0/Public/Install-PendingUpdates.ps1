function Install-PendingUpdates {
    [CmdletBinding()]
    param(
        # The name of the remote computer where updates will be checked and installed
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )

    begin {
        # Initialize $MissingUpdates as an empty array
        $MissingUpdates = @()
    }
    process {
        $scriptblock = {
            try {
                # Check for missing updates using WMI and ensure the result is treated as an array
                $MissingUpdates = @(Get-WmiObject -Class CCM_SoftwareUpdate -Filter ComplianceState=0 -Namespace root\CCM\ClientSDK)

                # Count the number of non-compliant updates
                $NonCompliantCount = $MissingUpdates.Count

                # Trigger the installation of updates if any are found
                if ($MissingUpdates) {
                    # Display the number and names of non-compliant updates found
                    Write-Host "$NonCompliantCount update(s) found:"
                    $MissingUpdates | ForEach-Object { Write-Host " - $($_.Name)" }
                    Write-Host
                    Write-Host "Initiating update installation..."
                    
                    # Initiate the updates using WMI
                    Invoke-WmiMethod -ComputerName $env:computername -Class CCM_SoftwareUpdatesManager -Name InstallUpdates -ArgumentList (, $MissingUpdates) -Namespace root\ccm\clientsdk | Out-Null
                    Write-Host "Updates initiated."
                }
                else {
                    Write-Host "No updates found."
                }
            }
            catch {
                # Log any errors encountered during the process
                Write-Error "An error occurred while checking for pending updates: $_"
            }
        }

        # Execute the script block on the specified remote computer
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptblock
    }
    end {
        Write-Host
    }
}
