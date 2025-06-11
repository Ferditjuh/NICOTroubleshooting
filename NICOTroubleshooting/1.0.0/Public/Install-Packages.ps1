function Install-Packages {
    [CmdletBinding()]
    param (
        # The name of the remote computer where the packages will be installed
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,

        # Path to the manifest list file containing package names
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ManifestList,

        # Path to the directory containing the package files
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageSource
    )

    begin {
        # Initialization code if needed
        # This block runs once before processing any input
    }
    process {
        $ScriptBlock = {
            try {
                # Import parameters from the parent scope
                $ManifestList = $using:ManifestList
                $PackageSource = $using:PackageSource

                # Check if the ManifestList file exists
                # If the file does not exist, log an error and exit the script block
                if (-not (Test-Path -Path $ManifestList)) {
                    Write-Error "Could not find the manifest list: $ManifestList"
                    return
                }

                # Check if the PackageSource path exists
                # If the directory does not exist, log an error and exit the script block
                if (-not (Test-Path -Path $PackageSource)) {
                    Write-Error "Could not find the package source: $PackageSource"
                    return
                }

                # Import the list of packages from the manifest file
                # Each line in the manifest file is treated as a package name
                $Packages = Get-Content -Path $ManifestList

                # Format the package source path to ensure it ends with a backslash
                $SourcePath = $PackageSource.TrimEnd('\') + "\"

                # Loop through each package and install it
                foreach ($Package in $Packages) {
                    # Construct the full path to the package file
                    $PackagePath = Join-Path -Path $SourcePath -ChildPath $Package

                    # Run the DISM command to install the package
                    DISM /Online /Add-Package /PackagePath:$PackagePath /NoRestart
                }

                # Notify the user that the process is complete
                Write-Host
                Write-Host "Completed processing the packages. Restart the computer to finalize the installation."
            }
            catch {
                Write-Error "An error occurred during package installation: $_"
            }
        }

        # Execute the script block on the specified remote computer
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock
    }
    end {
        Write-Host
    }
}
