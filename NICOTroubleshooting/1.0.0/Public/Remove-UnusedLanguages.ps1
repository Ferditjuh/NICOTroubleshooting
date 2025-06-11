function Remove-UnusedLanguages {
    [CmdletBinding()]
    param (
        # The folder path to scan for unused language files and folders
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FolderPath
    )

    begin {
        # Define a list of language identifiers to remove
        # These identifiers represent language codes that will be matched against file and folder names
        $languageIdentifiers = @(
            "ar-sa", "bg-bg", "cs-cz", "da-dk", "de-de", "el-gr", "en-gb", "es-es", 
            "es-mx", "et-ee", "fi-fi", "fr-ca", "fr-fr", "he-il", "hr-hr", "hu-hu", 
            "it-it", "ja-jp", "ko-kr", "lt-lt", "lv-lv", "nb-no", "nl-nl", "pl-pl",
            "pt-br", "pt-pt", "ro-ro", "ru-ru", "sk-sk", "sl-si", "sr-..-rs", "sv-se", 
            "th-th", "tr-tr", "uk-ua", "zh-cn", "zh-tw", "sr-Latn-RS"
        )
    }
    process {
        # Check if the folder exists
        # If the folder does not exist, log an error and exit the function
        if (-Not (Test-Path -Path $FolderPath)) {
            Write-Error "The specified folder does not exist: $FolderPath"
            return
        }

        # Get all files and folders in the specified folder
        $items = Get-ChildItem -Path $FolderPath

        # Iterate through each item in the folder
        foreach ($item in $items) {
            # Check each item against the list of language identifiers
            foreach ($language in $languageIdentifiers) {
                if ($item.Name -like "*$language*") {
                    if ($item.PSIsContainer) {
                        # If the item is a folder, delete its contents and the folder itself
                        Write-Host "Deleting folder: $($item.FullName)"
                        Remove-Item -Path $item.FullName -Recurse -Force
                    }
                    else {
                        # If the item is a file, delete the file
                        Write-Host "Deleting file: $($item.FullName)"
                        Remove-Item -Path $item.FullName -Force
                    }
                    # Break out of the inner loop once a match is found and processed
                    break
                }
            }
        }
        
        # Log a message indicating that all files and folders have been processed
        Write-Host "All files have been processed."
    }
    end {
        Write-Host
    }
}
