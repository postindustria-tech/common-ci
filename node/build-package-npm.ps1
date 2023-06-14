param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [Parameter(Mandatory=$true)]
    [array]$Packages,
    [string[]]$NoRemote = @()
)

Push-Location $RepoName

try {

    # Creating result folder for packages with relative path to common
    $packageFolder = New-Item -ItemType directory -Path ../package -Force

    foreach ($package in $Packages) {
        $path = Join-Path . $package

        Push-Location $path

        try {


            # All modules that reference other pipeline modules in this repository
            # have package.json files where the dependency is defined relative to
            # the local file system.
            # We need to change these dependencies to 'normal' remote NPM references
            # before creating the packages.
            # Remove package.json

            if($NoRemote -NotContains $package){
                Remove-Item -Path ./package.json -Force || $(throw "ERROR: Failed to remove package.json files.")
                Rename-Item -Path ./remote_package.json -NewName package.json || $(throw "ERROR: Failed to create remote package.json files.")
            }

            # Special case - if package is a '.' we can't just lint the subdir with
            # the same name, so instead we'll lint the first subdir with the name
            # that starts with 'fiftyone*'
            if ($package -eq '.') {
                $jsonContent = Get-Content -Raw -Path "./package.json" | ConvertFrom-Json
                $package = $jsonContent.name
                Write-Host "Current Directory Name: $package"
            }

            # Set version number for each package.
            Write-Output "Setting version for $package"
            npm version $Version

            # Create package
            Write-Output "Creating package - $package"
            npm pack || $(throw "ERROR: Failed to pack $package")



            # Moving tgz file to common/package
            Move-Item -Path "${package}-${Version}.tgz" -Destination (New-Item -ItemType directory -Path $packageFolder -Force)

        } finally {
            Pop-Location
        }
    }

} finally {
    Pop-Location
    $items = Get-ChildItem -Path ./ -Force

    foreach ($item in $items) {
        if ($item.Attributes -band [System.IO.FileAttributes]::Directory) {
            Write-Host "Directory: $($item.Name)"
        } else {
            Write-Host "File: $($item.Name)"
        }
    }
}