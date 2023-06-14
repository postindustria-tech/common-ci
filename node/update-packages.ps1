param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [array]$Packages
)

Push-Location $RepoName

try {

    foreach ($package in $Packages) {
        $path = Join-Path . $package
        Push-Location $path

        Write-Output "Updating dependencies for $package"

        $remotePackagePath = Join-Path -Path . -ChildPath "remote_package.json"

        if (Test-Path -Path $remotePackagePath ) {
            Write-Output "Remote package founded in $package"

            Rename-Item -Path ./package.json -NewName local_package.json
            Rename-Item -Path ./remote_package.json -NewName package.json

            npm update  --save

            Rename-Item -Path ./package.json -NewName remote_package.json
            Rename-Item -Path ./local_package.json -NewName package.json

        } else {
            npm update --save
        }

        Pop-Location

    }
} finally {
    #   npm install -g eslint
    Pop-Location
}

