function Restore-CPSAssemblies {
    [CmdletBinding()]
    param (
        # The name of the remote computer where the assemblies will be replaced
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,    

        # Path to a text file containing the names of corrupt assemblies, one per line
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CorruptAssembliesList,

        # Path to the directory containing clean copies of the assemblies
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RepairSource,

        # Name of the local administrator account to be granted permissions
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AdminAccount
    )

    begin {
        # Initialization code if needed
    }
    process {
        $ScriptBlock = {
            $CorruptAssembliesList = $using:CorruptAssembliesList
            $RepairSource = $using:RepairSource
            $AdminAccount = $using:AdminAccount

            # Validate input parameters
            if (-not (Test-Path $CorruptAssembliesList)) {
                throw "The file $CorruptAssembliesList does not exist."
            }
            if (-not (Test-Path $RepairSource)) {
                throw "The directory $RepairSource does not exist."
            }

            # Import the corrupt assembly names from a text file
            $CorruptAssemblies = Get-Content -Path $CorruptAssembliesList

            # Define the component store path
            $CPS = Join-Path -Path $env:SystemRoot -ChildPath "WinSxS\"

            # Ensure a trailing backslash for the repair source path
            $FormattedRepairSource = $RepairSource.TrimEnd('\') + "\"

            # Try repairing the assemblies
            try {
                # Take ownership of the component store parent folder
                takeown /f $CPS | Out-Null

                # Grant Full Control of the component store and inheriting objects to the admin account
                icacls $CPS /grant "${AdminAccount}:(OI)(CI)(F)" | Out-Null

                Write-Host
                Write-Host "Successfully took control of the component store."
                Write-Host

                # Delete each of the corrupt assemblies, place a clean copy in the component store, and restore permissions
                foreach ($Assembly in $CorruptAssemblies) {
                    # Define the corrupt assembly path
                    $AssemblyPath = Join-Path -Path $CPS -ChildPath $Assembly
                    
                    # Define the clean assembly copy path
                    $CleanCopyPath = Join-Path -Path $FormattedRepairSource -ChildPath $Assembly

                    try {
                        # Validate the clean assembly path
                        if (-not (Test-Path $CleanCopyPath)) {
                            Write-Warning "Clean assembly not found in repair source: $FormattedRepairSource"
                            Write-Warning "Skipping: $Assembly"
                            continue
                        }

                        if (Test-Path $AssemblyPath) {
                            Write-Host "Attempting to repair: $Assembly"
                            Write-Host "Taking control of the corrupt assembly."
                            
                            # Take ownership of the corrupt assembly
                            takeown /f $AssemblyPath /r /d y | Out-Null

                            # Assign full control of the corrupt assembly to the admin account
                            icacls $AssemblyPath /grant "${AdminAccount}:(OI)(CI)(F)" /t | Out-Null

                            Write-Host "Removing corrupt assembly."

                            # Delete the corrupt assembly
                            Remove-Item -Path $AssemblyPath -Recurse -Force | Out-Null

                            Write-Host "Successfully removed."
                        }
                        else {
                            Write-Warning "Assembly not found in component store: $AssemblyPath"
                            Write-Warning "Ignoring corrupt assembly removal. Moving on to replacement."
                        }

                        Write-Host "Attempting to replace with clean copy."

                        # Copy the clean copy of the assembly into the component store
                        Copy-Item -Path $CleanCopyPath -Destination $CPS -Recurse -Force | Out-Null

                        Write-Host "Setting permissions on the clean assembly."

                        # Disable permissions inheritance on the clean assembly
                        icacls $AssemblyPath /inheritance:d /t | Out-Null
                        
                        # Return ownership of the assembly to TrustedInstaller
                        icacls $AssemblyPath /setowner "NT SERVICE\TrustedInstaller" /t | Out-Null
                        
                        # Remove full control of the assembly from the admin account
                        icacls $AssemblyPath /remove:g $AdminAccount /t | Out-Null

                        Write-Host "Successfully replaced assembly: $Assembly"
                        Write-Host
                    }
                    catch {
                        Write-Error "Failed to process assembly ${Assembly}: $_"
                        Write-Host
                    }
                }
            }
            finally {
                Write-Host "Restoring permissions on the component store."

                # Ensure the component store permissions are returned to its original state
                icacls $CPS /setowner "NT SERVICE\TrustedInstaller" | Out-Null
                icacls $CPS /remove:g $AdminAccount | Out-Null

                Write-Host "Component store permissions restored to TrustedInstaller."
            }
        }

        Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock
    }
    end {
        Write-Host
    }
}
