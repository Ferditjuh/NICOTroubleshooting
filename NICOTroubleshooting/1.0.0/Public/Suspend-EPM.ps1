function Suspend-EPM {
    [CmdletBinding()]
    param (
        # The name of the remote computer where the EPM services will be suspended
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,

        # The secure token required to unlock EPM
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SecureToken
    )

    begin {
        # Initialization code if needed
    }
    process {
        $scriptblock = {
            $SecureToken = $using:SecureToken
            $VFAgent = "C:\Program Files\CyberArk\Endpoint Privilege Manager\Agent\vf_agent.exe"

            # Unlock EPM using the provided secure token
            Write-Host "Unlocking EPM..."
            Start-Process -FilePath $VFAgent -ArgumentList "-UseToken $SecureToken" -Wait | Out-Null

            # Stop the first EPM service
            Write-Host "Stopping first EPM service..."
            Start-Process -FilePath $VFAgent -ArgumentList "-StopServ" -Wait | Out-Null

            # Stop the second EPM service
            Write-Host "Stopping second EPM service..."
            Start-Process -FilePath $VFAgent -ArgumentList "-StopPasServ" -Wait | Out-Null

            # Confirm that the EPM services have been successfully stopped
            Write-Host "Successfully stopped EPM."
        }

        # Execute the script block on the specified remote computer
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptblock
    }
    end {
        Write-Host
    }
}
