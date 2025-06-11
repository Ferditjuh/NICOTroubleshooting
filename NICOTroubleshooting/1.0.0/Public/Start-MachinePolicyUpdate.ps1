function Start-MachinePolicyUpdate {
    [CmdletBinding()]
    param (
        # The name of the remote computer where the machine policy update will be triggered
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )

    begin {
        # Initialization code if needed
    }
    process {
        $scriptblock = {
            try {
                # Trigger a machine policy update for the Configuration Manager Client
                Invoke-CimMethod -Namespace "ROOT\ccm" -Class "SMS_Client" -Method "TriggerSchedule" -Arguments "{00000000-0000-0000-0000-000000000021}" -ErrorAction Stop
            }
            catch {
                # Handle any errors that occur during the execution of the Invoke-CimMethod command
                Write-Error "An error occurred while triggering the machine policy update: $_"
            }
        }

        # Execute the script block on the specified remote computer
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptblock
    }
    end {
        Write-Host
    }
}
