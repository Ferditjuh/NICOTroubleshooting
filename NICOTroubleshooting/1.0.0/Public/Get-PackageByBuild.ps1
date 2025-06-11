function Get-PackageByBuild {
    [CmdletBinding()]
    param (
        # The name of the remote computer where the package search will be performed
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,

        # The build number to search for in package manifest filenames
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Build
    )

    begin {
        # Initialization code if needed
        # This block runs once before processing any input
    }
    process {
        $ScriptBlock = {
            try {
                # Use the build number passed from the parent scope
                $Build = $using:Build
                $FolderPath = "C:\Windows\servicing\Packages"
                $Output = "C:\Temp\PackageManifests.txt"
                $Temp = "C:\Temp"
                
                Write-Host "Attempting to retrieve package manifests for build number: $Build"
                
                # Get all .mum package manifest files that match the specified build number
                $Packages = Get-ChildItem -Path $FolderPath -Filter "*.mum" | Where-Object { $_.Name -match $Build }

                # Ensure the C:\Temp directory exists; create it if it does not
                if (-not (Test-Path -Path $Temp)) {
                    New-Item -Path $Temp -ItemType Directory
                }

                # Remove the output file if it already exists to avoid appending to old data
                if (Test-Path -Path $Output) {
                    Remove-Item -Path $Output -Force
                }

                # Output the sorted list of matching package manifest filenames to a text file
                $Packages | Sort-Object Name | ForEach-Object { $_.Name } | Out-File -FilePath $Output -Encoding UTF8

                Write-Host "Manifest filenames successfully written to: $Output"
            }
            catch {
                # Handle any errors that occur during the retrieval or writing of package manifests
                Write-Error "An error occurred while retrieving or writing package manifests: $_"
            }
        }

        # Execute the script block on the specified remote computer
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock
    }
    end {
        Write-Host
    }
}
