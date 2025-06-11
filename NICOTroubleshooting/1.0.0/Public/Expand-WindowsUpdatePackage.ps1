function Expand-WindowsUpdatePackage {
    [CmdletBinding()]
    param (
        # The path to the .msu or .cab file to be expanded
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$filePath,

        # The destination directory where the files will be extracted
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$destinationPath
    )

    begin {
        # Display a note to the user
        Write-Host "==========================="
        Write-Host
        Write-Host "Note: Do not close any Windows opened by this script until it is completed."
        Write-Host
        Write-Host "==========================="
        Write-Host

        # Initialize a hashtable to track processed files
        $processedFiles = @{}
    }
    process {
        # Remove quotes if present
        $filePath = $filePath -replace '"', ''
        $destinationPath = $destinationPath -replace '"', ''

        # Trim trailing backslash if present
        $destinationPath = $destinationPath.TrimEnd('\')

        # Validate the file path
        if (-not (Test-Path $filePath -PathType Leaf)) {
            Write-Host "The specified file does not exist: $filePath"
            Write-Host
            return
        }

        # Validate or create the destination directory
        if (-not (Test-Path $destinationPath -PathType Container)) {
            Write-Host "Creating destination directory: $destinationPath"
            Write-Host
            New-Item -Path $destinationPath -ItemType Directory | Out-Null
        }

        # Define the function to expand a file
        function Expand-File ($file, $destination) {
            Write-Host "Expanding $file to $destination"
            Write-Host
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c expand.exe `"$file`" -f:* `"$destination`" > nul 2>&1" -Wait -WindowStyle Hidden
            $processedFiles[$file] = $true
            Write-Host "Expansion completed for $file"
            Write-Host
        }

        # Define the function to rename a file
        function Rename-File ($file) {
            if (Test-Path -Path $file) {
                $newName = [System.IO.Path]::GetFileNameWithoutExtension($file) + "_" + [System.Guid]::NewGuid().ToString("N") + [System.IO.Path]::GetExtension($file)
                $newPath = Join-Path -Path ([System.IO.Path]::GetDirectoryName($file)) -ChildPath $newName
                Write-Host "Renaming $file to $newPath"
                Rename-Item -Path $file -NewName $newPath
                Write-Host "Renamed $file to $newPath"
                Write-Host
                return $newPath
            }
            Write-Host "File $file does not exist for renaming"
            Write-Host
            return $null
        }

        # Define the function to recursively expand CAB files
        function Expand-CabFiles ($directory) {
            while ($true) {
                $cabFiles = Get-ChildItem -Path $directory -Filter "*.cab" -File | Where-Object { -not $processedFiles[$_.FullName] -and $_.Name -ne "wsusscan.cab" }

                if ($cabFiles.Count -eq 0) {
                    Write-Host "No more CAB files found in $directory"
                    Write-Host
                    break
                }

                foreach ($cabFile in $cabFiles) {
                    Write-Host "Processing CAB file $($cabFile.FullName)"
                    Write-Host
                    $cabFilePath = Rename-File -file $cabFile.FullName

                    if ($null -ne $cabFilePath) {
                        Expand-File -file $cabFilePath -destination $directory
                        Expand-CabFiles -directory $directory
                    }
                }
            }
        }

        try {
            # Initial extraction based on file type
            if ($filePath.EndsWith(".msu")) {
                Write-Host "Extracting .msu file to: $destinationPath"
                Write-Host
                Expand-File -file $filePath -destination $destinationPath
            }
            elseif ($filePath.EndsWith(".cab")) {
                Write-Host "Extracting .cab file to: $destinationPath"
                Write-Host
                Expand-File -file $filePath -destination $destinationPath
            }
            else {
                Write-Host "The specified file is not a .msu or .cab file: $filePath"
                Write-Host
                return
            }

            # Process all .cab files recursively
            Write-Host "Starting to process CAB files in $destinationPath"
            Write-Host
            Expand-CabFiles -directory $destinationPath
        }
        catch {
            Write-Host "An error occurred while extracting the file. Error: $_"
            return
        }

        Write-Host "Extraction completed. Files are located in $destinationPath"
        return $destinationPath
    }
    end {
        Write-Host
    }
}
