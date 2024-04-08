param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [array]$Packages,
    [array]$NeedExtensions
)

Push-Location $RepoName

try {
    foreach ($package in $Packages) {
        $path = Join-Path . $package
        Push-Location $path
        Write-Output "Installing dependencies for $package"

        npm install

        Write-Output "Linting $package"
        eslint . --ext .js

        if($NeedExtensions -Contains $package){
            & "$PSScriptRoot/build-extension.ps1" -PackageName $package
        }

        Pop-Location
    }
} finally {
    Pop-Location
}

